module Ottiv
  module Core
    module Controllers
      module Api
        module V1
          # Controller administrativo para buscar scheduled messages de todas as contas
          # Usado pelo scheduler para processar mensagens pendentes
          class ScheduledMessagesController < ::Api::BaseController
            # Busca mensagens pendentes de todas as contas
            # Requer autenticação via api_access_token
            def index
              # Buscar apenas mensagens pendentes de todas as contas
              @scheduled_messages = OttivScheduledMessage.pending
                                                       .includes(:creator, :conversation, :contact, :account)

              @scheduled_messages = @scheduled_messages.order(send_at: :asc)
              render json: @scheduled_messages.map { |msg| scheduled_message_to_json(msg) }
            end

            # Endpoint para o scheduler enviar uma mensagem agendada
            # A mensagem já tem account_id, então não precisa estar no escopo de accounts
            def send_message
              @scheduled_message = OttivScheduledMessage.find(params[:id])

              service = Ottiv::Core::Services::ScheduledMessages::SendService.new(@scheduled_message)
              message = service.perform

              render json: {
                success: true,
                message: message,
                scheduled_message: scheduled_message_to_json(@scheduled_message)
              }
            rescue ActiveRecord::RecordNotFound
              render json: { error: 'Scheduled message not found' }, status: :not_found
            rescue StandardError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            # Endpoint para marcar mensagem como failed (usado quando há erro antes de enviar)
            def mark_as_failed
              @scheduled_message = OttivScheduledMessage.find(params[:id])
              error_message = params[:error_message]

              @scheduled_message.mark_as_failed!(error_message)

              render json: {
                success: true,
                scheduled_message: scheduled_message_to_json(@scheduled_message)
              }
            rescue ActiveRecord::RecordNotFound
              render json: { error: 'Scheduled message not found' }, status: :not_found
            rescue StandardError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            # Endpoint para atualizar status (usado para marcar como failed via update)
            def update
              @scheduled_message = OttivScheduledMessage.find(params[:id])
              
              if params[:ottiv_scheduled_message][:status] == 'failed'
                error_message = params[:ottiv_scheduled_message][:error_message]
                @scheduled_message.mark_as_failed!(error_message)
                render json: scheduled_message_to_json(@scheduled_message)
              else
                render json: { error: 'Only status update to failed is allowed' }, status: :unprocessable_entity
              end
            rescue ActiveRecord::RecordNotFound
              render json: { error: 'Scheduled message not found' }, status: :not_found
            rescue StandardError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            private

            # Converte scheduled_message para JSON com timestamps em Unix timestamp (segundos)
            # Similar ao formato usado em conversations, messages e calendar_items
            def scheduled_message_to_json(message)
              json = message.as_json

              # Converter timestamps principais para Unix timestamp (segundos)
              json['send_at'] = message.send_at.to_i if message.send_at
              json['sent_at'] = message.sent_at.to_i if message.sent_at
              json['created_at'] = message.created_at.to_i
              json['updated_at'] = message.updated_at.to_i

              json
            end
          end
        end
      end
    end
  end

  end
