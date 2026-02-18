module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class DealPhasesController < ::Api::V1::Accounts::BaseController
            def show
              deal_phase = DealPhase.find_by(
                contact_id: params[:contact_id],
                deal_id: params[:deal_id] || params[:id]
              )

              if deal_phase.nil?
                render json: { error: 'Deal phase not found' }, status: :not_found
                return
              end

              render json: deal_phase.as_json
            rescue StandardError => e
              Rails.logger.error("❌ [OttivDealPhases] Erro ao buscar deal phase: #{e.class} - #{e.message}")
              Rails.logger.error(e.backtrace.join("\n"))
              render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end

            def by_deal
              deal_phases = DealPhase.where(
                deal_id: params[:deal_id],
                contact_id: params[:contact_id]
              )

              render json: deal_phases.as_json
            rescue StandardError => e
              Rails.logger.error("❌ [OttivDealPhases] Erro ao buscar deal phases: #{e.class} - #{e.message}")
              Rails.logger.error(e.backtrace.join("\n"))
              render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end
          end
        end
      end
    end
  end
end

