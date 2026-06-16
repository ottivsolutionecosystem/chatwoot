module Ottiv::Core
  module Services
    module CannedResponses
      class ListForAgentService
        def initialize(account:, user:, search: nil, personal_only: false, shared_only: false)
          @account = account
          @user = user
          @search = search.presence
          @personal_only = personal_only
          @shared_only = shared_only
        end

        def perform
          personal = shared_only?   ? [] : load_personal
          shared   = personal_only? ? [] : load_shared

          merged = merge(shared, personal)
          serialize(merged)
        end

        private

        def personal_only?
          @personal_only
        end

        def shared_only?
          @shared_only
        end

        def load_personal
          scope = @account.ottiv_personal_canned_responses.where(user_id: @user.id)
          if @search
            scope = scope.search(@search).order_by_search(@search)
          end
          scope.to_a
        end

        def load_shared
          scope = @account.canned_responses
          if @search
            scope = scope
              .where('short_code ILIKE :q OR content ILIKE :q', q: "%#{@search}%")
              .order_by_search(@search)
          end
          scope.to_a
        end

        # Merges shared + personal; personal takes precedence when short_code clashes.
        def merge(shared, personal)
          personal_codes = personal.map { |p| p.short_code.downcase }.to_set

          kept_shared = shared.reject { |s| personal_codes.include?(s.short_code.downcase) }

          # personal first so they appear at the top; then non-overlapping shared
          personal + kept_shared
        end

        def serialize(records)
          records.map { |r| serialize_one(r) }
        end

        def serialize_one(record)
          personal = record.is_a?(OttivPersonalCannedResponse)
          {
            id: record.id,
            short_code: record.short_code,
            content: record.content,
            personal: personal,
            created_at: record.created_at,
            updated_at: record.updated_at
          }
        end
      end
    end
  end
end
