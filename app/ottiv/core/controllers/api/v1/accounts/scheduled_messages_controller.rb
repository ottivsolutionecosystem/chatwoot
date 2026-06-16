module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class ScheduledMessagesController < ::Api::V1::Accounts::BaseController
            before_action :set_scheduled_message, only: [:show, :update, :destroy, :cancel_series]
            before_action :check_authorization, only: [:show, :update, :destroy, :cancel_series]

            def index
              @scheduled_messages = Current.account.ottiv_scheduled_messages
                                       .includes(:creator, :conversation, :contact)

              # Non-admins only see their own scheduled messages
              unless Current.user.administrator?
                @scheduled_messages = @scheduled_messages.where(created_by: Current.user.id)
              end

              # Filter by conversation — accept both display_id (frontend) and internal id
              if params[:conversation_id].present?
                conv = Current.account.conversations.find_by(display_id: params[:conversation_id]) ||
                       Current.account.conversations.find_by(id: params[:conversation_id])
                @scheduled_messages = @scheduled_messages.by_conversation(conv.id) if conv
              end

              # Filter by status
              @scheduled_messages = @scheduled_messages.by_status(params[:status]) if params[:status].present?

              # Filter by creator (admins only)
              @scheduled_messages = @scheduled_messages.where(created_by: params[:created_by]) if params[:created_by].present? && Current.user.administrator?

              # Filter pending (for scheduler to fetch)
              @scheduled_messages = @scheduled_messages.pending if params[:pending] == 'true'

              # Filter upcoming
              @scheduled_messages = @scheduled_messages.upcoming if params[:upcoming] == 'true'

              # Filter by send_at date range
              if params[:send_at_from].present? || params[:send_at_to].present?
                from = params[:send_at_from].present? ? Time.zone.parse(params[:send_at_from]) : nil
                to   = params[:send_at_to].present?   ? Time.zone.parse(params[:send_at_to])   : nil
                @scheduled_messages = @scheduled_messages.by_send_at_range(from, to)
              end

              @scheduled_messages = @scheduled_messages.order(send_at: :asc)
              render json: @scheduled_messages.map { |msg| scheduled_message_to_json(msg) }
            end

            def show
              render json: scheduled_message_to_json(@scheduled_message)
            end

            def create
              service = ::Ottiv::Core::Services::ScheduledMessages::CreateService.new(
                params: scheduled_message_params,
                user: Current.user,
                account: Current.account
              )

              @scheduled_message = service.perform
              render json: scheduled_message_to_json(@scheduled_message), status: :created
            rescue ArgumentError => e
              render json: { error: e.message }, status: :unprocessable_entity
            rescue ActiveRecord::RecordInvalid => e
              render json: {
                error: e.record.errors.full_messages.join(', '),
                errors: e.record.errors.as_json
              }, status: :unprocessable_entity
            rescue StandardError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            def update
              # Only allow updating status (to cancel)
              if params[:ottiv_scheduled_message][:status] == 'cancelled'
                @scheduled_message.cancel!
                render json: scheduled_message_to_json(@scheduled_message)
              else
                render json: { error: 'Only status update to cancelled is allowed' }, status: :unprocessable_entity
              end
            end

            def destroy
              @scheduled_message.cancel!
              head :no_content
            end

            # Cancels all still-scheduled occurrences in the same series.
            # Falls back to cancelling only this record for legacy messages
            # that have no series_id.
            def cancel_series
              @scheduled_message.cancel_series!
              render json: {
                cancelled: true,
                series_id: @scheduled_message.series_id,
                message: @scheduled_message.series_id.present? ? 'Series cancelled' : 'Message cancelled (no series_id)'
              }
            rescue StandardError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            def send_message
              # Endpoint para o scheduler Node enviar a mensagem
              @scheduled_message = Current.account.ottiv_scheduled_messages.find(params[:id])

              service = ::Ottiv::Core::Services::ScheduledMessages::SendService.new(@scheduled_message)
              message = service.perform

              render json: {
                success: true,
                message: message,
                scheduled_message: @scheduled_message
              }
            rescue StandardError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            private

            def set_scheduled_message
              @scheduled_message = Current.account.ottiv_scheduled_messages.find(params[:id])
            rescue ActiveRecord::RecordNotFound
              render json: { error: 'Scheduled message not found' }, status: :not_found
            end

            def check_authorization
              unless @scheduled_message.created_by == Current.user.id || Current.user.administrator?
                render json: { error: 'Unauthorized' }, status: :forbidden
              end
            end

            def scheduled_message_params
              params.require(:ottiv_scheduled_message).permit(
                :title,
                :message_type,
                :content,
                :media_url,
                :audio_url,
                :quick_reply_id,
                :conversation_id,
                :contact_id,
                :send_at,
                :timezone,
                :recurrence
              )
            end

            # Converts timestamps to Unix (seconds) for consistency with the rest of the API.
            def scheduled_message_to_json(message)
              json = message.as_json

              json['send_at']    = message.send_at.to_i    if message.send_at
              json['sent_at']    = message.sent_at.to_i    if message.sent_at
              json['created_at'] = message.created_at.to_i
              json['updated_at'] = message.updated_at.to_i

              # IMPORTANT — Chatwoot conversation ID conventions:
              #
              # Every Chatwoot conversation has two numeric identifiers:
              #   • id          — internal Rails primary key (e.g. 5958). Used only for
              #                   ActiveRecord associations and direct DB queries. The
              #                   Chatwoot REST API does NOT accept this value in URL paths.
              #   • display_id  — sequential, account-scoped number shown to users (e.g. 972).
              #                   This is what the Chatwoot API uses in every route:
              #                   GET /api/v1/accounts/:account_id/conversations/:display_id
              #                   and it is the value the frontend stores as `conversation.id`.
              #
              # We always expose display_id as `conversation_id` so the frontend can use it
              # both for display (#972) and for API/navigation calls (?conversation=972).
              if message.conversation_id.present? && message.conversation
                json['conversation_id'] = message.conversation.display_id
              end

              # Include contact name
              if message.contact_id.present? && message.contact
                json['contact_name'] = message.contact.name
              elsif message.conversation_id.present? && message.conversation&.contact
                json['contact_name'] = message.conversation.contact.name
              end

              json
            end
          end
        end
      end
    end
  end
end
