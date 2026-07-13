# frozen_string_literal: true

module Ottiv::Core::Services::Finance
  class NegotiationService
    NOT_SOLD_REASONS = {
      'installment_high' => 'Parcela alta',
      'down_payment' => 'Entrada inviável',
      'bought_elsewhere' => 'Comprou em outra loja',
      'gave_up' => 'Desistiu da compra',
      'credit_issue' => 'Problema de crédito',
      'cash_payment' => 'Optou por pagamento à vista',
      'other' => 'Outro'
    }.freeze

    CUSTOMER_FIELD_MAP = {
      'endereco' => 'address',
      'email' => 'email',
      'nome_mae' => 'motherName',
      'renda' => 'income',
      'profissao' => 'profession'
    }.freeze

    def initialize(auth:)
      @auth = auth
    end

    def list(filters = {})
      scope = @auth.scoped_negotiations.recent_first
      scope = scope.where(conversation_id: filters[:conversation_id]) if filters[:conversation_id].present?
      scope = scope.where(contact_id: filters[:contact_id]) if filters[:contact_id].present?
      scope = scope.where(status: filters[:status]) if filters[:status].present?
      scope
    end

    def create!(params)
      @auth.authorize_create!

      timestamp = Time.current
      submit = ActiveModel::Type::Boolean.new.cast(params[:submit])
      customer = (params[:customer] || {}).deep_stringify_keys.except('conversationId')
      conditions = build_conditions(params[:conditions], customer)

      negotiation = OttivFinanceNegotiation.create!(
        account_id: @auth.account.id,
        conversation_id: params[:conversation_id],
        contact_id: params[:contact_id],
        deal_id: params[:deal_id],
        finance_conversation_linked: params[:conversation_id].present?,
        status: submit ? 'submitted' : 'draft',
        priority: params[:priority].presence || 'medium',
        customer: customer,
        vehicle: params[:vehicle],
        conditions: conditions,
        submitted_at: submit ? timestamp : nil,
        created_by_id: @auth.user.id,
        updated_by_id: @auth.user.id
      )

      add_timeline!(negotiation, 'created', 'Negociação criada', timestamp)
      add_timeline!(negotiation, 'submitted', 'Enviado para F&I', timestamp) if submit

      refresh_ai_insight!(negotiation)
      reload!(negotiation)
    end

    def update!(negotiation, params)
      raise ArgumentError, 'Negociação encerrada não pode ser editada' if negotiation.closed?

      if params[:customer]
        negotiation.customer = negotiation.customer.merge(params[:customer].deep_stringify_keys.except('conversationId'))
      end
      negotiation.vehicle = params[:vehicle] if params.key?(:vehicle)
      if params[:conditions]
        negotiation.conditions = negotiation.conditions.merge(params[:conditions].deep_stringify_keys)
        recalc_financed_amount!(negotiation)
      end
      negotiation.priority = params[:priority] if params[:priority].present?
      negotiation.updated_by_id = @auth.user.id
      negotiation.save!

      add_timeline!(negotiation, 'note', 'Negociação atualizada')
      refresh_ai_insight!(negotiation)
      reload!(negotiation)
    end

    def submit!(negotiation)
      raise ArgumentError, 'Negociação encerrada não pode ser editada' if negotiation.closed?

      timestamp = Time.current
      negotiation.update!(
        status: 'submitted',
        submitted_at: timestamp,
        updated_by_id: @auth.instance_variable_get(:@user).id
      )
      add_timeline!(negotiation, 'submitted', 'Enviado para F&I', timestamp)
      refresh_ai_insight!(negotiation)
      reload!(negotiation)
    end

    def query_banks!(negotiation, bank_codes: nil)
      @auth.authorize_fi_action!

      adapter = BankAdapters::StubAdapter.new
      timestamp = Time.current
      banks = adapter.query(negotiation, bank_codes: bank_codes)

      banks.each do |bank|
        offer = negotiation.offers.create!(
          bank_code: bank[:bank_code],
          bank_name: bank[:bank_name],
          status: bank[:status],
          queried_at: bank[:queried_at] || timestamp
        )
        create_installments!(offer, bank[:installment_options] || [])
      end

      negotiation.update!(status: 'querying', updated_by_id: @auth.instance_variable_get(:@user).id)
      add_timeline!(
        negotiation,
        'bank_query',
        'Consulta enviada aos bancos',
        timestamp,
        banks.map { |b| b[:bank_name] }.join(', ')
      )
      reload!(negotiation)
    end

    def add_bank_opinion!(negotiation, params)
      @auth.authorize_fi_action!

      timestamp = Time.current
      offer = negotiation.offers.create!(
        bank_code: params[:bank_code],
        bank_name: params[:bank_name],
        status: params[:status],
        opinion_outcome: params[:opinion_outcome],
        retorno: params[:retorno],
        required_down_payment: params[:required_down_payment],
        approved_financed_amount: params[:approved_financed_amount],
        financing_percent: params[:financing_percent],
        fi_notes: params[:fi_notes],
        rejection_reason: params[:rejection_reason],
        pending_items: params[:pending_items] || [],
        requested_docs: params[:requested_docs] || [],
        queried_at: timestamp,
        responded_at: timestamp
      )
      create_installments!(offer, params[:installment_options] || [])

      if params[:status] == 'docs_required' && params[:requested_docs].present?
        params[:requested_docs].each do |doc_label|
          negotiation.documents.create!(
            doc_type: doc_label.to_s.downcase.gsub(/\s+/, '_'),
            label: doc_label,
            kind: 'file',
            status: 'requested',
            requested_at: timestamp,
            requested_by_id: @auth.user.id
          )
        end
        add_timeline!(
          negotiation,
          'docs_requested',
          'Documentação solicitada',
          timestamp,
          params[:requested_docs].join(', ')
        )
      end

      negotiation.updated_by_id = @auth.user.id
      negotiation.save!
      ComputeStatusService.call(negotiation)
      add_timeline!(
        negotiation,
        'bank_response',
        "#{params[:bank_name]} #{outcome_label(params[:opinion_outcome])}",
        timestamp,
        opinion_description(params)
      )
      reload!(negotiation)
    end

    def update_bank_opinion!(negotiation, offer_id, params)
      @auth.authorize_fi_action!
      raise ArgumentError, 'Negociação encerrada não pode ser editada' if negotiation.closed?

      offer = negotiation.offers.find(offer_id)
      timestamp = Time.current

      offer.update!(
        status: params[:status],
        opinion_outcome: params[:opinion_outcome],
        retorno: params[:retorno],
        required_down_payment: params[:required_down_payment],
        approved_financed_amount: params[:approved_financed_amount],
        financing_percent: params[:financing_percent],
        fi_notes: params[:fi_notes],
        rejection_reason: params[:rejection_reason],
        pending_items: params[:pending_items] || [],
        requested_docs: params[:requested_docs] || [],
        responded_at: timestamp
      )

      existing_marks = offer.installments.order(:id).map(&:marks)
      offer.installments.destroy_all
      create_installments!(offer, params[:installment_options] || [], existing_marks: existing_marks)

      negotiation.updated_by_id = @auth.user.id
      negotiation.save!
      ComputeStatusService.call(negotiation)
      add_timeline!(
        negotiation,
        'bank_response',
        "#{offer.bank_name} — parecer atualizado (#{outcome_label(params[:opinion_outcome])})",
        timestamp,
        params[:fi_notes]
      )
      reload!(negotiation)
    end

    def request_documents!(negotiation, params)
      @auth.authorize_fi_action!

      timestamp = Time.current
      existing_types = negotiation.documents.pluck(:doc_type)
      created_labels = []

      (params[:documents] || []).each do |doc|
        doc_type = doc[:type] || doc['type']
        next if existing_types.include?(doc_type)

        doc_label = doc[:label] || doc['label']
        negotiation.documents.create!(
          doc_type: doc_type,
          label: doc_label,
          kind: doc[:kind] || doc['kind'] || document_kind(doc_type),
          status: 'requested',
          requested_at: timestamp,
          requested_by_id: @auth.instance_variable_get(:@user).id,
          notes: params[:notes]
        )
        existing_types << doc_type
        created_labels << doc_label
      end

      return reload!(negotiation) if created_labels.empty?

      negotiation.updated_by_id = @auth.user.id
      negotiation.save!
      add_timeline!(
        negotiation,
        'docs_requested',
        'Documentação solicitada',
        timestamp,
        created_labels.join(', ')
      )
      reload!(negotiation)
    end

    def upload_document!(negotiation, document_id, file:, file_name: nil)
      doc = negotiation.documents.find(document_id)
      timestamp = Time.current

      doc.file.attach(file) if file.present?
      doc.update!(
        status: 'received',
        received_at: timestamp,
        file_name: file_name || file&.original_filename || 'documento.pdf'
      )

      negotiation.updated_by_id = @auth.user.id
      negotiation.save!
      add_timeline!(negotiation, 'docs_received', "#{doc.label} recebido", timestamp)
      reload!(negotiation)
    end

    def provide_document_data!(negotiation, document_id, value:)
      doc = negotiation.documents.find(document_id)
      timestamp = Time.current
      customer = negotiation.customer.deep_dup

      field = CUSTOMER_FIELD_MAP[doc.doc_type]
      if doc.doc_type == 'sem_aprovacao_novo_cpf'
        digits = value.to_s.gsub(/\D/, '')
        customer['cpf'] = digits if digits.length >= 11
      elsif field == 'income'
        customer['income'] = parse_money(value)
      elsif field
        customer[field] = value
      end

      doc.update!(status: 'received', received_at: timestamp, value: value)
      negotiation.update!(customer: customer, updated_by_id: @auth.instance_variable_get(:@user).id)
      add_timeline!(negotiation, 'docs_received', "#{doc.label} informado", timestamp, value)
      reload!(negotiation)
    end

    def mark_installment!(negotiation, offer_id, installment_id, mark:)
      offer = negotiation.offers.find(offer_id)
      installment = offer.installments.find(installment_id)
      marks = installment.marks || []
      marks << mark unless marks.include?(mark)
      installment.update!(marks: marks)
      negotiation.update!(updated_by_id: @auth.instance_variable_get(:@user).id)
      reload!(negotiation)
    end

    def close!(negotiation, params)
      @auth.authorize_fi_action!
      raise ArgumentError, 'Negociação já encerrada' if negotiation.closed?

      if params[:outcome] == 'not_sold' && params[:not_sold_reason].blank?
        raise ArgumentError, 'Informe o motivo da não compra'
      end
      if params[:not_sold_reason] == 'other' && params[:reason_notes].to_s.strip.blank?
        raise ArgumentError, 'Descreva o motivo da não compra'
      end

      timestamp = Time.current
      reason_label = NOT_SOLD_REASONS[params[:not_sold_reason]]

      if params[:outcome] == 'sold'
        negotiation.assign_attributes(
          status: 'closed',
          closure_outcome: 'sold',
          closure_notes: params[:reason_notes]
        )
        description = params[:reason_notes].presence || 'Cliente comprou o veículo'
        title = 'Encerrada — Cliente comprou'
      else
        negotiation.assign_attributes(
          status: 'lost',
          closure_outcome: 'not_sold',
          closure_reason: params[:not_sold_reason],
          closure_notes: params[:reason_notes]
        )
        description = [reason_label, params[:reason_notes]].compact.join(' — ')
        title = 'Encerrada — Cliente não comprou'
      end

      negotiation.closed_at = timestamp
      negotiation.updated_by_id = @auth.user.id
      negotiation.save!
      add_timeline!(negotiation, 'closed', title, timestamp, description)
      reload!(negotiation)
    end

    def record_proposal_sent!(negotiation)
      negotiation.update!(updated_by_id: @auth.instance_variable_get(:@user).id)
      add_timeline!(negotiation, 'proposal_sent', 'Proposta enviada ao cliente')
      reload!(negotiation)
    end

    private

    def reload!(negotiation)
      negotiation.reload
      negotiation.offers.reload
      negotiation.documents.reload
      negotiation.timeline_events.reload
      negotiation
    end

    def build_conditions(conditions, customer)
      base = (conditions || {}).deep_stringify_keys
      base['hasCnh'] = customer['hasCnh'] unless base.key?('hasCnh')
      base['financingType'] ||= 'cdc'
      base
    end

    def recalc_financed_amount!(negotiation)
      price = negotiation.conditions['vehiclePrice']
      down = negotiation.conditions['downPayment']
      return unless price && down

      negotiation.conditions['financedAmount'] = price.to_f - down.to_f
    end

    def refresh_ai_insight!(negotiation)
      negotiation.update!(ai_insight: ComputePreAnalysisService.call(negotiation))
    end

    def add_timeline!(negotiation, type, title, timestamp = Time.current, description = nil)
      negotiation.timeline_events.create!(
        event_type: type,
        title: title,
        description: description,
        created_by_id: @auth.user.id,
        created_at: timestamp
      )
    end

    def create_installments!(offer, options, existing_marks: nil)
      options.each_with_index do |opt, index|
        marks = existing_marks&.[](index) || []
        offer.installments.create!(
          installments: opt[:installments] || opt['installments'],
          installment_value: opt[:installment_value] || opt['installmentValue'],
          rate: opt[:rate] || opt['rate'],
          cet: opt[:cet] || opt['cet'],
          marks: marks
        )
      end
    end

    def outcome_label(outcome)
      case outcome
      when 'approved_full' then 'aprovou 100%'
      when 'approved_with_down' then 'aprovou com entrada'
      when 'rejected' then 'recusou'
      when 'docs_required' then 'solicitou docs'
      else 'em análise'
      end
    end

    def opinion_description(params)
      parts = []
      parts << "Retorno #{params[:retorno]}" if params[:retorno]
      parts << "Entrada mín. #{params[:required_down_payment]}" if params[:required_down_payment]
      parts << "Financia #{params[:approved_financed_amount]}" if params[:approved_financed_amount]
      parts << "#{params[:financing_percent]}%" if params[:financing_percent]
      if params[:installment_options].present?
        parts << params[:installment_options].map do |o|
          val = o[:installment_value] || o['installmentValue']
          inst = o[:installments] || o['installments']
          "#{inst}x #{val}"
        end.join(' | ')
      end
      parts << params[:rejection_reason] if params[:rejection_reason]
      parts << params[:fi_notes] if params[:fi_notes]
      parts.compact.join(' · ').presence
    end

    def document_kind(type)
      %w[endereco email nome_mae renda profissao sem_aprovacao_novo_cpf].include?(type) ? 'data' : 'file'
    end

    def parse_money(value)
      cleaned = value.to_s.gsub(/[^\d,.-]/, '').tr('.', '').tr(',', '.')
      cleaned.present? ? cleaned.to_f : nil
    end
  end
end
