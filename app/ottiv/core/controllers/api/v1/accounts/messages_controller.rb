module Core
  module Controllers
    module Api
      module V1
        module Accounts
          class MessagesController < ::Api::V1::Accounts::BaseController
            # GET /api/v1/accounts/:account_id/ottiv_messages/:message_id/conversation
            # Retorna a conversa associada à mensagem usando display_id
            def conversation
              # Buscar mensagem
              message = Current.account.messages.find_by!(id: params[:message_id])
                
              # Buscar a conversa usando o id interno (conversation_id da mensagem)
              @conversation = Current.account.conversations
                .where(id: message.conversation_id)
                .includes(
                  :taggings,
                  :inbox,
                  { assignee: { avatar_attachment: [:blob] } },
                  { contact: { avatar_attachment: [:blob] } },
                  :team,
                  :contact_inbox
                )
                .first
                
              if @conversation.nil?
                render json: { error: 'Conversa não encontrada' }, status: :not_found
                return
              end
                
              # Aplicar permissões (verificar se usuário tem acesso)
              authorize @conversation, :show?
                
              # Usar scope ottiv_with_list_data para incluir unread_count
              # E pré-carregar última mensagem para evitar N+1
              @conversation = Conversation
                .ottiv_with_list_data
                .where(id: @conversation.id)
                .includes(
                  :taggings,
                  :inbox,
                  { assignee: { avatar_attachment: [:blob] } },
                  { contact: { avatar_attachment: [:blob] } },
                  :team,
                  :contact_inbox
                )
                .first
                
              # Pré-carregar última mensagem
              Conversation.ottiv_preload_last_messages([@conversation])
            rescue ActiveRecord::RecordNotFound => e
              render json: { error: 'Mensagem não encontrada' }, status: :not_found
            rescue Pundit::NotAuthorizedError
              render json: { error: 'Acesso negado' }, status: :forbidden
            rescue StandardError => e
              Rails.logger.error("❌ [OttivMessages] Erro ao buscar conversa da mensagem: #{e.class} - #{e.message}")
              Rails.logger.error(e.backtrace.join("\n"))
              render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end
          end
        end
      end
    end
  end
end

