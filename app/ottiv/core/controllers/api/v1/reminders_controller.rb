module Ottiv::Core
  module Controllers
    module Api
      module V1
        # Controller administrativo para buscar reminders de todas as contas
        # Usado pelo scheduler para processar reminders pendentes
        class RemindersController < ::Api::BaseController
          # Busca reminders pendentes de todas as contas
          # Requer autenticação via api_access_token
          def index
            # Buscar apenas reminders pendentes de todas as contas
            @reminders = OttivReminder.pending
                                    .includes(ottiv_calendar_item: [:participants, :account, :user])

            @reminders = @reminders.order(notify_at: :asc)

            # Incluir participantes, account e user no JSON
            render json: @reminders.as_json(
              include: {
                ottiv_calendar_item: {
                  include: {
                    participants: {},
                    account: {},
                    user: {}
                  }
                }
              }
            )
          end

          # Atualiza um reminder (marca como enviado)
          # A reminder já tem calendar_item que tem account_id, então não precisa estar no escopo de accounts
          def update
            @reminder = OttivReminder.find(params[:id])

            if @reminder.update(reminder_params)
              render json: @reminder
            else
              render json: { errors: @reminder.errors.full_messages }, status: :unprocessable_entity
            end
          rescue ActiveRecord::RecordNotFound
            render json: { error: 'Reminder not found' }, status: :not_found
          end

          private

          def reminder_params
            params.require(:ottiv_reminder).permit(:sent)
          end
        end
      end
    end
  end
end

