module Ottiv
  module Core
    module Controllers
      module Api
        module V1
          module Accounts
            class DealsController < ::Api::V1::Accounts::BaseController
              def process
                # Processa deal baseado em conversation_id, contact_id e account_id
                deal = Deal.find_by(
                  account_id: Current.account.id,
                  conversation_id: params[:conversation_id],
                  contact_id: params[:contact_id]
                )

                if deal.nil?
                  render json: { error: 'Deal not found' }, status: :not_found
                  return
                end

                # Retornar dados do deal com relacionamentos
                render json: {
                  deal: deal.as_json(include: [:deal_phase, :deal_products, :deal_registrations]),
                  deal_phase: deal.deal_phase&.as_json,
                  deal_products: deal.deal_products.as_json(include: [:product]),
                  deal_registrations: deal.deal_registrations.as_json
                }
              rescue StandardError => e
                Rails.logger.error("❌ [OttivDeals] Erro ao processar deal: #{e.class} - #{e.message}")
                Rails.logger.error(e.backtrace.join("\n"))
                render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
              end

              private

              def deal_params
                params.permit(:conversation_id, :contact_id)
              end
            end
          end
        end
      end
    end
  end

  end
