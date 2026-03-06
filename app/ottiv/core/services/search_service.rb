module Ottiv::Core
module Services
  class SearchService
      pattr_initialize [:current_user!, :current_account!, :params!]

      def perform
        search_query = (params[:q] || params[:searchTerm]).to_s.strip
        return empty_result if search_query.blank?

        # Buscar contatos que correspondem ao termo
        contacts = find_matching_contacts(search_query)
          
        # Para cada contato, buscar conversas aplicando filtros
        results = contacts.map do |contact|
          build_contact_result(contact)
        end.compact

        # Ordenar contatos por last_activity_at_desc (conversa mais recente primeiro)
        results = sort_results_by_activity(results)

        # Buscar mensagens separadamente que correspondem ao termo
        messages = find_matching_messages(search_query)

        {
          results: results,
          messages: messages,
          meta: build_meta(results, messages)
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
            page: params[:page] || 1,
            per_page: 15
          }
        }
      end

      def find_matching_contacts(search_query)
        search = "%#{search_query}%"
        current_account.contacts
          .where(
            "name ILIKE :search OR email ILIKE :search OR phone_number ILIKE :search OR identifier ILIKE :search",
            search: search
          )
          .resolved_contacts(use_crm_v2: current_account.feature_enabled?('crm_v2'))
          .limit(15) # Limitar contatos para evitar sobrecarga
      end

      def build_contact_result(contact)
        # Buscar conversas do contato aplicando filtros
        conversations = find_conversations_for_contact(contact.id)
        return nil if conversations.empty?

        # Formatar conversas
        conversations_data = conversations.map do |conversation|
          {
            id: conversation.display_id,
            status: conversation.status,
            inbox_id: conversation.inbox_id,
            last_activity_at: conversation.last_activity_at.to_i,
            unread_count: conversation.ottiv_unread_count || 0,
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
        # Obter inboxes acessíveis pelo usuário
        accessable_inbox_ids = current_user.assigned_inboxes.pluck(:id)
        return [] if accessable_inbox_ids.empty?

        query = current_account.conversations
          .where(contact_id: contact_id)

        # Aplicar filtro de inbox_ids
        if params[:inbox_ids].present? && params[:inbox_ids].is_a?(Array) && params[:inbox_ids].any?
          # Filtrar apenas pelas inboxes que o usuário tem acesso E que foram solicitadas
          filtered_inbox_ids = accessable_inbox_ids & params[:inbox_ids].map(&:to_i).compact
          if filtered_inbox_ids.empty?
            return [] # Se não há inboxes válidas, retornar vazio
          end
          query = query.where(inbox_id: filtered_inbox_ids)
        else
          # Sem filtro de inbox, usar todas as inboxes acessíveis
          query = query.where(inbox_id: accessable_inbox_ids)
        end

        # Aplicar filtro de status
        if params[:status].present? && params[:status] != 'all'
          query = query.where(status: params[:status])
        end

        # Aplicar filtro de conversation_type (mention)
        if params[:conversation_type].present? && params[:conversation_type] == 'mention'
          query = query.joins(:messages)
            .where("messages.content LIKE '%[@%](mention://%'")
        end

        # Aplicar filtro de assignee_type
        case params[:assignee_type]
        when 'me'
          query = query.where(assignee_id: current_user.id)
        when 'unassigned'
          query = query.where("assignee_id IS NULL OR assignee_id = 0")
        when 'all'
          # Não filtrar por assignee
        end

        # Aplicar filtro de assignee_ids (múltiplos assignees)
        if params[:assignee_ids].present? && params[:assignee_ids].is_a?(Array) && params[:assignee_ids].any?
          assignee_ids_array = params[:assignee_ids].map(&:to_i).compact.reject(&:zero?)
          include_unassigned = params[:include_unassigned] == true

          if assignee_ids_array.any? && include_unassigned
            # Combinar assignee_ids específicos + não atribuídas
            query = query.where(
              "assignee_id IN (?) OR assignee_id IS NULL OR assignee_id = 0",
              assignee_ids_array
            )
          elsif assignee_ids_array.any?
            # Apenas assignee_ids específicos
            query = query.where(assignee_id: assignee_ids_array)
          elsif include_unassigned
            # Apenas não atribuídas
            query = query.where("assignee_id IS NULL OR assignee_id = 0")
          end
        end

        # Aplicar filtro de labels
        needs_distinct = false
        if params[:label_titles].present? && params[:label_titles].is_a?(Array) && params[:label_titles].any?
          label_titles_array = params[:label_titles].map(&:to_s).compact.reject(&:blank?)
          if label_titles_array.any?
            query = query.tagged_with(label_titles_array, any: true)
            needs_distinct = true
          end
        end

        # Aplicar filtro de prioridades
        if params[:priorities].present? && params[:priorities].is_a?(Array) && params[:priorities].any?
          allowed_priorities = %w[low medium high urgent]
          priorities_array = params[:priorities].map(&:to_s).compact.select { |priority| allowed_priorities.include?(priority) }
          if priorities_array.any?
            query = query.where(priority: priorities_array)
          end
        end

        # Aplicar filtro de data (last_activity_at)
        if params[:date_from].present?
          from_time = Time.zone.at(params[:date_from].to_i)
          query = query.where('conversations.last_activity_at >= ?', from_time)
        end

        if params[:date_to].present?
          # Para date_to, incluir todo o dia (até 23:59:59.999)
          to_time = Time.zone.at(params[:date_to].to_i).end_of_day
          query = query.where('conversations.last_activity_at <= ?', to_time)
        end

        # Aplicar ottiv_with_list_data DEPOIS de todos os joins e filtros
        # mas ANTES do distinct para evitar conflitos com SELECT
        query = query.ottiv_with_list_data

        # Aplicar distinct se necessário (depois de ottiv_with_list_data)
        query = query.distinct if needs_distinct || params[:conversation_type].present?

        # Ordenar
        sort_by = params[:sort_by] || 'last_activity_at_desc'
        case sort_by
        when 'last_activity_at_desc'
          query = query.order('conversations.last_activity_at DESC')
        when 'last_activity_at_asc'
          query = query.order('conversations.last_activity_at ASC')
        when 'created_at_desc'
          query = query.order('conversations.created_at DESC')
        when 'created_at_asc'
          query = query.order('conversations.created_at ASC')
        end

        # Executar query com includes e retornar array
        query.includes(:assignee, :contact).limit(50).to_a
      end

      def find_matching_messages(search_query)
        search = "%#{search_query}%"
          
        # Obter inboxes acessíveis pelo usuário
        accessable_inbox_ids = current_user.assigned_inboxes.pluck(:id)
        return [] if accessable_inbox_ids.empty?

        # Buscar mensagens que correspondem ao termo
        # Primeiro buscar IDs de conversas das inboxes acessíveis
        conversation_ids = current_account.conversations
          .where(inbox_id: accessable_inbox_ids)
          .pluck(:id)
          
        return [] if conversation_ids.empty?
          
        messages = current_account.messages
          .where('content ILIKE :search', search: search)
          .where(message_type: [Message.message_types[:incoming], Message.message_types[:outgoing]])
          .where(conversation_id: conversation_ids)
          .includes(conversation: :contact, sender: [])
          .order('created_at DESC')
          .limit(50) # Limitar mensagens totais

        # Formatar mensagens com dados da conversa
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

      def sort_results_by_activity(results)
        sort_by = params[:sort_by] || 'last_activity_at_desc'
        case sort_by
        when 'last_activity_at_desc'
          results.sort do |a, b|
            max_a = a[:conversations].map { |c| c[:last_activity_at] }.max || 0
            max_b = b[:conversations].map { |c| c[:last_activity_at] }.max || 0
            max_b <=> max_a
          end
        when 'last_activity_at_asc'
          results.sort do |a, b|
            max_a = a[:conversations].map { |c| c[:last_activity_at] }.max || 0
            max_b = b[:conversations].map { |c| c[:last_activity_at] }.max || 0
            max_a <=> max_b
          end
        else
          results
        end
      end

      def build_meta(results, messages)
        total_conversations = results.sum { |r| r[:conversations].count }

        {
          total_contacts: results.count,
          total_conversations: total_conversations,
          total_messages: messages.count,
          page: params[:page] || 1,
          per_page: 15
        }
      end
    end
  end
end

