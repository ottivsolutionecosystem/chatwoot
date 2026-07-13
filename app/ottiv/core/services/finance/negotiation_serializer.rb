# frozen_string_literal: true

module Ottiv::Core::Services::Finance
  class NegotiationSerializer
    def self.serialize(negotiation)
      new(negotiation).as_json
    end

    def self.serialize_collection(negotiations)
      negotiations.map { |n| serialize(n) }
    end

    def initialize(negotiation)
      @negotiation = negotiation
    end

    def as_json
      {
        id: @negotiation.id.to_s,
        status: @negotiation.status,
        priority: @negotiation.priority,
        conversationId: @negotiation.conversation_id,
        contactId: @negotiation.contact_id,
        dealId: @negotiation.deal_id,
        financeConversationLinked: @negotiation.finance_conversation_linked,
        customer: @negotiation.customer || {},
        vehicle: @negotiation.vehicle.presence,
        conditions: @negotiation.conditions || {},
        offers: @negotiation.offers.map { |o| serialize_offer(o) },
        documents: @negotiation.documents.map { |d| serialize_document(d) },
        timeline: @negotiation.timeline_events.sort_by(&:created_at).reverse.map { |e| serialize_timeline(e) },
        aiInsight: @negotiation.ai_insight.presence,
        createdAt: @negotiation.created_at.iso8601,
        updatedAt: @negotiation.updated_at.iso8601,
        submittedAt: @negotiation.submitted_at&.iso8601,
        closedAt: @negotiation.closed_at&.iso8601,
        closureOutcome: @negotiation.closure_outcome,
        closureReason: @negotiation.closure_reason,
        closureNotes: @negotiation.closure_notes
      }
    end

    private

    def serialize_offer(offer)
      {
        id: offer.id.to_s,
        bankCode: offer.bank_code,
        bankName: offer.bank_name,
        status: offer.status,
        opinionOutcome: offer.opinion_outcome,
        installmentOptions: offer.installments.map { |i| serialize_installment(i) },
        retorno: offer.retorno,
        requiredDownPayment: decimal_or_nil(offer.required_down_payment),
        approvedFinancedAmount: decimal_or_nil(offer.approved_financed_amount),
        financingPercent: decimal_or_nil(offer.financing_percent),
        fiNotes: offer.fi_notes,
        rejectionReason: offer.rejection_reason,
        pendingItems: offer.pending_items || [],
        requestedDocs: offer.requested_docs || [],
        queriedAt: offer.queried_at&.iso8601,
        respondedAt: offer.responded_at&.iso8601,
        rawResponse: offer.raw_response.presence
      }
    end

    def serialize_installment(installment)
      {
        id: installment.id.to_s,
        installments: installment.installments,
        installmentValue: decimal_or_nil(installment.installment_value),
        rate: decimal_or_nil(installment.rate),
        cet: decimal_or_nil(installment.cet),
        marks: installment.marks || []
      }
    end

    def serialize_document(doc)
      payload = {
        id: doc.id.to_s,
        type: doc.doc_type,
        label: doc.label,
        kind: doc.kind,
        status: doc.status,
        requestedAt: doc.requested_at&.iso8601,
        receivedAt: doc.received_at&.iso8601,
        requestedBy: doc.requested_by_id ? requested_by_name(doc.requested_by_id) : nil,
        fileName: doc.file_name,
        value: doc.value,
        notes: doc.notes
      }

      if doc.file.attached?
        payload[:fileUrl] = Rails.application.routes.url_helpers.rails_blob_path(
          doc.file,
          only_path: true
        )
      end

      payload
    end

    def serialize_timeline(event)
      {
        id: event.id.to_s,
        type: event.event_type,
        title: event.title,
        description: event.description,
        createdAt: event.created_at.iso8601,
        createdBy: event.creator&.available_name || event.creator&.name,
        metadata: event.metadata.presence
      }
    end

    def requested_by_name(user_id)
      User.find_by(id: user_id)&.available_name
    end

    def decimal_or_nil(value)
      return nil if value.nil?

      value.to_f
    end
  end
end
