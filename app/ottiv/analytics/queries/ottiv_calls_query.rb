# frozen_string_literal: true

module Ottiv::Analytics
  module Queries
    class OttivCallsQuery
      def initialize(account:, params: {})
        @account = account
        @params = params
      end

      def relation
        scope = OttivCall.where(account_id: @account.id)
        scope = scope.where(provider: @params[:provider]) if @params[:provider].present?
        scope = scope.where(status: @params[:status]) if @params[:status].present?

        if @params[:conversation_id].present?
          conv = @account.conversations.find_by(display_id: @params[:conversation_id]) ||
                 @account.conversations.find_by(id: @params[:conversation_id])
          scope = conv ? scope.where(conversation_id: conv.id) : scope.none
        end

        if @params[:from].present?
          scope = scope.where('ottiv_calls.created_at >= ?', Time.zone.parse(@params[:from].to_s))
        end
        if @params[:to].present?
          scope = scope.where('ottiv_calls.created_at <= ?', Time.zone.parse(@params[:to].to_s))
        end

        agent_filter_id = optional_user_id_filter
        scope = scope.where(user_id: agent_filter_id) if agent_filter_id.present?

        scope.order(created_at: :desc)
      end

      def summary_by_status
        relation.reorder(nil).group(:status).count
      end

      def summary_by_day
        relation.reorder(nil).group("date_trunc('day', ottiv_calls.created_at AT TIME ZONE 'UTC')").count
      end

      def summary_by_user_id
        relation.reorder(nil).group(:user_id).count.transform_keys { |k| k.nil? ? 'null' : k.to_s }
      end

      private

      def optional_user_id_filter
        (@params[:user_id].presence || @params[:agent_id].presence)
      end
    end
  end
end
