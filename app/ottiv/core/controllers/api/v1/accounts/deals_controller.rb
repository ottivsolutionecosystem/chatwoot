module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class DealsController < ::Api::V1::Accounts::BaseController
            # GET /api/v1/accounts/:account_id/ottiv_deals/by_contact
            # Busca todas as deals vinculadas a um contato
            def by_contact
              contact_id = params[:contact_id]

              if contact_id.blank?
                render json: { error: 'contact_id é obrigatório' }, status: :bad_request
                return
              end

              deals = Deal.where(
                account_id: @current_account.id,
                contact_id: contact_id
              ).includes(:user)
               .order(updated_at: :desc)

              render json: {
                deals: deals.map { |deal| serialize_deal(deal) },
                meta: {
                  total: deals.count,
                  contact_id: contact_id
                }
              }
            rescue StandardError => e
              Rails.logger.error("❌ [OttivDeals] Erro ao buscar deals por contato: #{e.class} - #{e.message}")
              Rails.logger.error(e.backtrace.join("\n"))
              render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end

            # GET /api/v1/accounts/:account_id/ottiv_deals/by_conversation
            # Busca a deal vinculada a uma conversa específica (1:1 com o contato)
            def by_conversation
              deal = Deal.find_by(
                account_id: @current_account.id,
                conversation_id: params[:conversation_id],
                contact_id: params[:contact_id]
              )

              if deal.nil?
                render json: { error: 'Deal not found' }, status: :not_found
                return
              end

              render json: {
                deal: serialize_deal(deal),
                deal_phase: deal.deal_phases&.first&.as_json,
                deal_products: deal.deal_products.as_json,
                deal_registrations: deal.deal_registrations.as_json
              }
            rescue StandardError => e
              Rails.logger.error("❌ [OttivDeals] Erro ao buscar deal por conversa: #{e.class} - #{e.message}")
              Rails.logger.error(e.backtrace.join("\n"))
              render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end

            private

            # Serializa uma deal incluindo dados de pipeline_stage e pipeline (via SQL)
            def serialize_deal(deal)
              {
                id: deal.id,
                title: deal.title,
                description: deal.description,
                value: deal.value,
                currency: deal.currency,
                status: deal.status,
                source: deal.source,
                lead_value: deal.lead_value,
                expected_close_date: deal.expected_close_date,
                financial: deal.financial,
                returns: deal.returns,
                contact_id: deal.contact_id,
                conversation_id: deal.conversation_id,
                account_id: deal.account_id,
                created_at: deal.created_at,
                updated_at: deal.updated_at,
                stage: deal.pipeline_stage_data,
                pipeline: deal.pipeline_data,
                assignee: deal.user ? {
                  id: deal.user.id,
                  name: deal.user.name,
                  email: deal.user.email
                } : nil
              }
            end
          end
        end
      end
    end
  end
end
