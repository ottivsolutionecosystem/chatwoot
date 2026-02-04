module Core
  module Controllers
    module Api
      module V1
        module Accounts
          class ConfigController < ::Api::V1::Accounts::BaseController
            def show
              config = Config.find_by(account_id: Current.account.id)

              if config.nil?
                render json: { error: 'Config not found' }, status: :not_found
                return
              end

              render json: config.as_json
            rescue StandardError => e
              Rails.logger.error("❌ [OttivConfig] Erro ao buscar config: #{e.class} - #{e.message}")
              Rails.logger.error(e.backtrace.join("\n"))
              render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end
          end
        end
      end
    end
  end
end

