module Ottiv::Core
module Services
  class SearchService
      pattr_initialize [:current_user!, :current_account!, :params!]

      PER_PAGE = 15
      MAX_RECENT_MESSAGES = 50

      def perform
        search_query = (params[:q] || params[:searchTerm]).to_s.strip
        return empty_result if search_query.blank?

        # Dígitos puros para casar telefones com qualquer máscara.
        # Aceita override pelo frontend (params[:q_digits]) — mais barato que recalcular.
        digits_query = (params[:q_digits].presence || extract_digits(search_query)).to_s

        page = [params[:page].to_i, 1].max
        offset = (page - 1) * PER_PAGE

        # Contatos
        contacts_scope = matching_contacts_scope(search_query, digits_query)
        total_contacts = count_contacts(contacts_scope)
        contacts = paginate_contacts(contacts_scope, offset)
        results = contacts.map { |contact| build_contact_result(contact) }.compact

        # Mensagens
        messages_scope = matching_messages_scope(search_query)
        total_messages = count_messages(messages_scope)
        messages = format_messages(paginate_messages(messages_scope, offset))

        total_conversations = results.sum { |r| r[:conversations].count }

        {
          results: results,
          messages: messages,
          meta: {
            total_contacts: total_contacts,
            total_conversations: total_conversations,
            total_messages: total_messages,
            page: page,
            per_page: PER_PAGE
          }
        }
      end

      private

      def empty_result
        {
          results: [],
          messages: [],
          meta: {
            total_contacts: 0,
            total_conversations: 0,
            total_messages: 0,
            page: [params[:page].to_i, 1].max,
            per_page: PER_PAGE
          }
        }
      end

      # ---------------------------------------------------------------------
      # Contatos
      # ---------------------------------------------------------------------

      # Scope completo (sem LIMIT/OFFSET) com:
      # - WHERE textual case+acento insensível em name/email; phone_number normalizado
      # - INNER JOIN com agregação das conversas filtradas (garante "tem pelo menos
      #   uma conversa que passa nos filtros" e expõe last_activity_at para ordenar)
      def matching_contacts_scope(search_query, digits_query)
        search_like = "%#{search_query}%"
        # Escopo agregado: contact_id => MAX(last_activity_at) das conversas
        # acessíveis E que passam pelos filtros vigentes (status, assignee, etc.)
        agg_sql = filtered_conversations_scope
          .select('conversations.contact_id, MAX(conversations.last_activity_at) AS last_activity_at')
          .group('conversations.contact_id')
          .to_sql

        scope = current_account.contacts
          .joins(Arel.sql("INNER JOIN (#{agg_sql}) AS lc ON lc.contact_id = contacts.id"))
          .resolved_contacts(use_crm_v2: current_account.feature_enabled?('crm_v2'))

        if digits_query.length >= 4
          scope.where(
            "immutable_unaccent(coalesce(contacts.name, '')) ILIKE immutable_unaccent(:search) " \
            "OR contacts.email ILIKE :search " \
            "OR regexp_replace(coalesce(contacts.phone_number, ''), '\\D', '', 'g') ILIKE :digits",
            search: search_like,
            digits: "%#{digits_query}%"
          )
        else
          scope.where(
            "immutable_unaccent(coalesce(contacts.name, '')) ILIKE immutable_unaccent(:search) " \
            "OR contacts.email ILIKE :search " \
            "OR contacts.phone_number ILIKE :search",
            search: search_like
          )
        end
      end

      def paginate_contacts(scope, offset)
        scope
          .select('contacts.*, lc.last_activity_at AS lc_last_activity_at')
          .order(contacts_order_clause)
          .offset(offset)
          .limit(PER_PAGE)
          .to_a
      end

      def contacts_order_clause
        case params[:sort_by]
        when 'last_activity_at_asc'
          Arel.sql('lc.last_activity_at ASC NULLS LAST, contacts.id ASC')
        when 'created_at_desc'
          Arel.sql('contacts.created_at DESC, contacts.id DESC')
        when 'created_at_asc'
          Arel.sql('contacts.created_at ASC, contacts.id ASC')
        else
          Arel.sql('lc.last_activity_at DESC NULLS LAST, contacts.id DESC')
        end
      end

      # Conta contacts.id distintos. O scope possui INNER JOIN agregado, então
      # contamos a coluna explicitamente para evitar duplicações por joins.
      def count_contacts(scope)
        scope.except(:order, :limit, :offset, :select).distinct.count('contacts.id')
      rescue ActiveRecord::StatementInvalid
        scope.except(:order, :limit, :offset).pluck('contacts.id').uniq.size
      end

      def count_messages(scope)
        scope.except(:order, :limit, :offset, :select).distinct.count('messages.id')
      rescue ActiveRecord::StatementInvalid
        scope.except(:order, :limit, :offset).pluck('messages.id').uniq.size
      end

      def build_contact_result(contact)
        conversations = find_conversations_for_contact(contact.id)
        return nil if conversations.empty?

        conversations_data = conversations.map do |conversation|
          {
            id: conversation.display_id,
            status: conversation.status,
            inbox_id: conversation.inbox_id,
            last_activity_at: conversation.last_activity_at.to_i,
            unread_count: conversation.try(:ottiv_unread_count) || 0,
            assignee: conversation.assignee ? {
              id: conversation.assignee.id,
              name: conversation.assignee.name,
              available_name: conversation.assignee.available_name
            } : nil
          }
        end

        {
          contact: {
            id: contact.id,
            name: contact.name,
            email: contact.email,
            phone_number: contact.phone_number,
            identifier: contact.identifier,
            thumbnail: contact.avatar_url
          },
          conversations: conversations_data
        }
      end

      def find_conversations_for_contact(contact_id)
        scope = filtered_conversations_scope.where(contact_id: contact_id)
        return [] if scope.is_a?(Symbol) # filtro inválido sinalizando "vazio"

        scope = scope.ottiv_with_list_data
        scope = scope.distinct if needs_distinct?
        scope = apply_sort(scope)
        scope.includes(:assignee, :contact).limit(50).to_a
      end

      # ---------------------------------------------------------------------
      # Mensagens
      # ---------------------------------------------------------------------

      def matching_messages_scope(search_query)
        search_like = "%#{search_query}%"
        conversation_ids = filtered_conversations_scope.select('conversations.id')

        current_account.messages
          .where(conversation_id: conversation_ids)
          .where(message_type: [Message.message_types[:incoming], Message.message_types[:outgoing]])
          .where(
            "immutable_unaccent(coalesce(messages.content, '')) ILIKE immutable_unaccent(:search)",
            search: search_like
          )
      end

      def paginate_messages(scope, offset)
        scope
          .includes(conversation: :contact, sender: [])
          .order(messages_order_clause)
          .offset(offset)
          .limit(PER_PAGE)
          .to_a
      end

      def messages_order_clause
        case params[:sort_by]
        when 'last_activity_at_asc', 'created_at_asc'
          Arel.sql('messages.created_at ASC')
        else
          Arel.sql('messages.created_at DESC')
        end
      end

      def format_messages(messages)
        messages.map do |message|
          conversation = message.conversation
          {
            id: message.id,
            content: message.content,
            message_type: message.message_type,
            private: message.private || false,
            created_at: message.created_at.to_i,
            conversation_id: message.conversation_id,
            sender: message.sender ? {
              id: message.sender.id,
              name: message.sender.name
            } : nil,
            conversation: conversation ? {
              id: conversation.display_id,
              inbox_id: conversation.inbox_id,
              contact: {
                id: conversation.contact.id,
                name: conversation.contact.name,
                email: conversation.contact.email,
                phone_number: conversation.contact.phone_number,
                identifier: conversation.contact.identifier,
                thumbnail: conversation.contact.avatar_url
              },
              status: conversation.status
            } : nil
          }
        end
      end

      # ---------------------------------------------------------------------
      # Filtros compartilhados (status / assignee / inbox / labels / prioridade / data)
      # Retorna um relation já filtrado, sem joins de listagem (ottiv_with_list_data).
      # ---------------------------------------------------------------------

      def filtered_conversations_scope
        @filtered_conversations_scope ||= build_filtered_conversations_scope
      end

      def build_filtered_conversations_scope
        accessable_inbox_ids = current_user.assigned_inboxes.pluck(:id)
        return current_account.conversations.none if accessable_inbox_ids.empty?

        query = current_account.conversations

        # inbox_ids: intersecção com inboxes acessíveis
        if params[:inbox_ids].present? && params[:inbox_ids].is_a?(Array) && params[:inbox_ids].any?
          filtered_inbox_ids = accessable_inbox_ids & params[:inbox_ids].map(&:to_i).compact
          return current_account.conversations.none if filtered_inbox_ids.empty?

          query = query.where(inbox_id: filtered_inbox_ids)
        else
          query = query.where(inbox_id: accessable_inbox_ids)
        end

        # status
        if params[:status].present? && params[:status] != 'all'
          query = query.where(status: params[:status])
        end

        # mention (junta messages, exige distinct em queries finais)
        if params[:conversation_type].present? && params[:conversation_type] == 'mention'
          query = query.joins(:messages)
            .where("messages.content LIKE '%[@%](mention://%'")
        end

        # assignee_type
        case params[:assignee_type]
        when 'me'
          query = query.where(assignee_id: current_user.id)
        when 'unassigned'
          query = query.where('assignee_id IS NULL OR assignee_id = 0')
        end

        # assignee_ids + include_unassigned
        if params[:assignee_ids].present? && params[:assignee_ids].is_a?(Array) && params[:assignee_ids].any?
          assignee_ids_array = params[:assignee_ids].map(&:to_i).compact.reject(&:zero?)
          include_unassigned = params[:include_unassigned] == true

          if assignee_ids_array.any? && include_unassigned
            query = query.where(
              'assignee_id IN (?) OR assignee_id IS NULL OR assignee_id = 0',
              assignee_ids_array
            )
          elsif assignee_ids_array.any?
            query = query.where(assignee_id: assignee_ids_array)
          elsif include_unassigned
            query = query.where('assignee_id IS NULL OR assignee_id = 0')
          end
        end

        # labels
        if params[:label_titles].present? && params[:label_titles].is_a?(Array) && params[:label_titles].any?
          label_titles_array = params[:label_titles].map(&:to_s).compact.reject(&:blank?)
          query = query.tagged_with(label_titles_array, any: true) if label_titles_array.any?
        end

        # priorities
        if params[:priorities].present? && params[:priorities].is_a?(Array) && params[:priorities].any?
          allowed_priorities = %w[low medium high urgent]
          priorities_array = params[:priorities].map(&:to_s).compact.select { |priority| allowed_priorities.include?(priority) }
          query = query.where(priority: priorities_array) if priorities_array.any?
        end

        # data (last_activity_at)
        if params[:date_from].present?
          query = query.where('conversations.last_activity_at >= ?', Time.zone.at(params[:date_from].to_i))
        end

        if params[:date_to].present?
          query = query.where('conversations.last_activity_at <= ?', Time.zone.at(params[:date_to].to_i).end_of_day)
        end

        query
      end

      def needs_distinct?
        labels = params[:label_titles]
        has_label_filter = labels.is_a?(Array) && labels.compact.reject(&:blank?).any?
        has_label_filter || params[:conversation_type].present?
      end

      def apply_sort(scope)
        case params[:sort_by]
        when 'last_activity_at_asc'
          scope.order('conversations.last_activity_at ASC')
        when 'created_at_desc'
          scope.order('conversations.created_at DESC')
        when 'created_at_asc'
          scope.order('conversations.created_at ASC')
        else
          scope.order('conversations.last_activity_at DESC')
        end
      end

      # ---------------------------------------------------------------------
      # Helpers
      # ---------------------------------------------------------------------

      def extract_digits(value)
        value.to_s.gsub(/\D/, '')
      end
    end
  end
end
