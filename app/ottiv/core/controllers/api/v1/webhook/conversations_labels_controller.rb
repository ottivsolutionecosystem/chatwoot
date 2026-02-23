module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Webhook
          class ConversationsLabelsController < ::Api::BaseController
            before_action :set_current_account

            def index
              @labels = Current.account.labels.select(:id, :title, :color)
              render json: { payload: @labels.map { |label| { title: label.title, color: label.color } } }
            rescue StandardError => e
              Rails.logger.error("❌ [WebhookConversationsLabels] Erro ao buscar labels: #{e.class} - #{e.message}")
              Rails.logger.error(e.backtrace.join("\n"))
              render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end

            private

            def set_current_account
              account_id = request.headers['x-account'] || request.headers['HTTP_X_ACCOUNT']
              
              if account_id.blank?
                render json: { error: 'x-account header is required' }, status: :bad_request
                return
              end

              account = Account.find_by(id: account_id.to_i)
              
              if account.nil?
                render json: { error: 'Account not found' }, status: :not_found
                return
              end

              Current.account = account
            end
          end
        end
      end
    end
  end
end

