module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class SellersController < ::Api::V1::Accounts::BaseController
            def queue
              # Retorna fila de vendedores disponíveis
              # Implementação básica - pode ser expandida conforme necessário
              sellers = User.where(account_id: Current.account.id, role: 'agent')
                            .where(availability_status: 'online')
                            .order(:last_activity_at)

              render json: {
                sellers: sellers.as_json(only: [:id, :name, :email, :availability_status, :last_activity_at]),
                queue_length: sellers.count
              }
            rescue StandardError => e
              Rails.logger.error("❌ [OttivSellers] Erro ao buscar fila de vendedores: #{e.class} - #{e.message}")
              Rails.logger.error(e.backtrace.join("\n"))
              render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end

            def assign
              seller_id = params[:seller_id]
              conversation_id = params[:conversation_id]

              conversation = Current.account.conversations.find(conversation_id)
              seller = Current.account.users.find(seller_id)

              conversation.assignee = seller
              conversation.save!

              render json: {
                success: true,
                conversation: conversation.as_json,
                assignee: seller.as_json(only: [:id, :name, :email])
              }
            rescue ActiveRecord::RecordNotFound => e
              render json: { error: 'Conversation or seller not found' }, status: :not_found
            rescue StandardError => e
              Rails.logger.error("❌ [OttivSellers] Erro ao atribuir vendedor: #{e.class} - #{e.message}")
              Rails.logger.error(e.backtrace.join("\n"))
              render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end
          end
        end
      end
    end
  end
end

