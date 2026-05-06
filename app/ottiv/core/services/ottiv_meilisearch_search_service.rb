# frozen_string_literal: true

module Ottiv
  module Core
    module Services
      # Adapter de busca que usa Meilisearch para filtrar IDs e Postgres para
      # hidratar os campos voláteis (unread_count, assignee, status atual).
      #
      # Mesma interface pública que SearchService:
      #   .new(current_user:, current_account:, params:).perform
      #   → { results:, messages:, meta: }
      #
      # Em qualquer erro/timeout do Meilisearch, faz fallback automático para
      # SearchService (Postgres) — sem indisponibilidade da busca.
      class OttivMeilisearchSearchService
        PER_PAGE = SearchService::PER_PAGE

        def initialize(current_user:, current_account:, params:)
          @current_user    = current_user
          @current_account = current_account
          @params          = params
          @client          = OttivMeilisearchClient.new
        end

        def perform
          q = (@params[:q] || @params[:searchTerm]).to_s.strip
          return fallback.perform if q.blank?

          contacts_result, messages_result = parallel_meili_search(q)

          contact_ids = contacts_result['hits'].map { |h| h['contact_id'] }.compact
          message_ids = messages_result['hits'].map { |h| h['message_id'] }.compact

          results  = hydrate_contacts(contact_ids)
          messages = hydrate_messages(message_ids)

          total_contacts  = contacts_result.dig('totalHits') || contacts_result.dig('estimatedTotalHits') || 0
          total_messages  = messages_result.dig('totalHits') || messages_result.dig('estimatedTotalHits') || 0
          total_conversations = results.sum { |r| r[:conversations].size }

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
        rescue ::Ottiv::Meilisearch::Error => e
          Rails.logger.warn("[OttivMeili] fallback PG após erro: #{e.message}")
          fallback.perform
        end

        private

        # ── Meilisearch ───────────────────────────────────────────────────────

        def parallel_meili_search(q)
          offset       = (page - 1) * PER_PAGE
          contacts_uid = OttivIndexNaming.contacts_uid(@current_account.id)
          messages_uid = OttivIndexNaming.messages_uid(@current_account.id)

          queries = [
            build_contacts_query(q, contacts_uid, offset),
            build_messages_query(q, messages_uid, offset)
          ]

          response = @client.multi_search(queries: queries)
          results  = response['results'] || []
          [results[0] || {}, results[1] || {}]
        end

        def build_contacts_query(q, uid, offset)
          query = {
            indexUid: uid,
            q: q,
            offset: offset,
            limit: PER_PAGE,
            attributesToRetrieve: %w[contact_id],
            sort: [contacts_sort_clause]
          }

          filters = contacts_filters
          query[:filter] = filters if filters.present?
          query
        end

        def build_messages_query(q, uid, offset)
          query = {
            indexUid: uid,
            q: q,
            offset: offset,
            limit: PER_PAGE,
            attributesToRetrieve: %w[message_id],
            filter: ['private = false', 'message_type IN [0, 1]'] + messages_filters,
            sort: [messages_sort_clause]
          }
          query[:filter].compact!
          query
        end

        # ── Filtros Meilisearch ────────────────────────────────────────────────

        def contacts_filters
          [] # contatos não têm filtros de conversa diretos no índice
        end

        def messages_filters
          filters = []

          # inbox_ids — interseção com inboxes acessíveis (segurança)
          inbox_ids = effective_inbox_ids
          filters << "inbox_id IN [#{inbox_ids.join(', ')}]" if inbox_ids.any?

          # status
          status = @params[:status]
          filters << "conversation_status = #{status}" if status.present? && status != 'all'

          # assignee
          case @params[:assignee_type]
          when 'me'
            filters << "conversation_assignee_id = #{@current_user.id}"
          when 'unassigned'
            filters << 'conversation_assignee_id = 0 OR conversation_assignee_id NOT EXISTS'
          end

          if (ids = Array(@params[:assignee_ids]).map(&:to_i).compact.reject(&:zero?)).any?
            if @params[:include_unassigned]
              filters << "(conversation_assignee_id IN [#{ids.join(', ')}] OR conversation_assignee_id = 0)"
            else
              filters << "conversation_assignee_id IN [#{ids.join(', ')}]"
            end
          end

          # labels
          if (labels = Array(@params[:label_titles]).compact.reject(&:blank?)).any?
            filters << "conversation_labels IN [\"#{labels.join('", "')}\"]"
          end

          # priorities
          if (prios = Array(@params[:priorities]).compact.reject(&:blank?)).any?
            filters << "conversation_priority IN [\"#{prios.join('", "')}\"]"
          end

          # datas
          filters << "conversation_last_activity_at >= #{@params[:date_from].to_i}" if @params[:date_from].present?
          filters << "conversation_last_activity_at <= #{@params[:date_to].to_i}"   if @params[:date_to].present?

          filters
        end

        def effective_inbox_ids
          accessible = @current_user.assigned_inboxes.pluck(:id)
          requested  = Array(@params[:inbox_ids]).map(&:to_i).compact
          requested.any? ? (accessible & requested) : accessible
        end

        def contacts_sort_clause
          case @params[:sort_by]
          when 'last_activity_at_asc' then 'last_activity_at:asc'
          when 'created_at_desc'      then 'last_activity_at:desc'
          when 'created_at_asc'       then 'last_activity_at:asc'
          else                             'last_activity_at:desc'
          end
        end

        def messages_sort_clause
          case @params[:sort_by]
          when 'last_activity_at_asc', 'created_at_asc' then 'created_at:asc'
          else                                                'created_at:desc'
          end
        end

        # ── Hidratação Postgres ───────────────────────────────────────────────

        def hydrate_contacts(contact_ids)
          return [] if contact_ids.empty?

          contacts = Contact.where(id: contact_ids).index_by(&:id)

          conversations_by_contact = load_conversations_for_contacts(contact_ids)

          contact_ids.filter_map do |cid|
            contact = contacts[cid]
            next unless contact

            convs = conversations_by_contact[cid] || []
            next if convs.empty?

            build_contact_result(contact, convs)
          end
        end

        def load_conversations_for_contacts(contact_ids)
          # Uma única query com window function para pegar até 50 conversas por contato
          accessible_inbox_ids = @current_user.assigned_inboxes.pluck(:id)
          return {} if accessible_inbox_ids.empty?

          base_scope = @current_account.conversations
                                       .where(contact_id: contact_ids)
                                       .where(inbox_id: accessible_inbox_ids)

          base_scope = apply_conversation_filters(base_scope)

          base_scope
            .includes(:assignee, :contact)
            .ottiv_with_list_data
            .order('conversations.last_activity_at DESC')
            .to_a
            .group_by(&:contact_id)
            .transform_values { |convs| convs.first(50) }
        end

        def apply_conversation_filters(scope)
          status = @params[:status]
          scope = scope.where(status: status) if status.present? && status != 'all'

          case @params[:assignee_type]
          when 'me'        then scope = scope.where(assignee_id: @current_user.id)
          when 'unassigned' then scope = scope.where('assignee_id IS NULL OR assignee_id = 0')
          end

          if (ids = Array(@params[:assignee_ids]).map(&:to_i).reject(&:zero?)).any?
            if @params[:include_unassigned]
              scope = scope.where('assignee_id IN (?) OR assignee_id IS NULL OR assignee_id = 0', ids)
            else
              scope = scope.where(assignee_id: ids)
            end
          end

          if (labels = Array(@params[:label_titles]).compact.reject(&:blank?)).any?
            scope = scope.tagged_with(labels, any: true)
          end

          if (prios = Array(@params[:priorities]).compact.reject(&:blank?)).any?
            scope = scope.where(priority: prios)
          end

          scope = scope.where('conversations.last_activity_at >= ?',
                               Time.zone.at(@params[:date_from].to_i)) if @params[:date_from].present?
          scope = scope.where('conversations.last_activity_at <= ?',
                               Time.zone.at(@params[:date_to].to_i).end_of_day) if @params[:date_to].present?

          scope
        end

        def build_contact_result(contact, conversations)
          conversations_data = conversations.map do |conv|
            {
              id: conv.display_id,
              status: conv.status,
              inbox_id: conv.inbox_id,
              last_activity_at: conv.last_activity_at.to_i,
              unread_count: conv.try(:ottiv_unread_count) || 0,
              assignee: conv.assignee ? {
                id: conv.assignee.id,
                name: conv.assignee.name,
                available_name: conv.assignee.available_name
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

        def hydrate_messages(message_ids)
          return [] if message_ids.empty?

          messages = Message.where(id: message_ids)
                            .includes(conversation: :contact, sender: [])
                            .index_by(&:id)

          message_ids.filter_map { |mid| messages[mid] }.then { |msgs| format_messages(msgs) }
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

        # ── Helpers ───────────────────────────────────────────────────────────

        def page
          [@params[:page].to_i, 1].max
        end

        def fallback
          SearchService.new(
            current_user:    @current_user,
            current_account: @current_account,
            params:          @params
          )
        end
      end
    end
  end
end
