module Ottiv
  module Core
    module Controllers
      module Api
        module V1
          module Accounts
            class ContactsController < ::Api::V1::Accounts::BaseController
              # GET /api/v1/accounts/:account_id/ottiv_contacts/:contact_id/last_conversation
              # Query params: inbox_id (opcional)
              def last_conversation
                contact = Current.account.contacts.find_by!(id: params[:contact_id])
                
                # Buscar última conversa do contato
                # Se inbox_id for fornecido, filtrar por inbox
                conversations_query = Current.account.conversations
                  .where(contact_id: contact.id)
                  .includes(
                    :taggings,
                    :inbox,
                    { assignee: { avatar_attachment: [:blob] } },
                    { contact: { avatar_attachment: [:blob] } },
                    :team,
                    :contact_inbox
                  )
                
                # Filtrar por inbox_id se fornecido
                if params[:inbox_id].present?
                  conversations_query = conversations_query.where(inbox_id: params[:inbox_id])
                end
                
                # Buscar última conversa ordenada por last_activity_at
                @conversation = conversations_query
                  .order(last_activity_at: :desc)
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
                render json: { error: 'Contato não encontrado' }, status: :not_found
              rescue Pundit::NotAuthorizedError
                render json: { error: 'Acesso negado' }, status: :forbidden
              rescue StandardError => e
                Rails.logger.error("❌ [OttivContacts] Erro ao buscar última conversa: #{e.class} - #{e.message}")
                Rails.logger.error(e.backtrace.join("\n"))
                render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
              end
            end
          end
        end
      end
    end
  end

  end
