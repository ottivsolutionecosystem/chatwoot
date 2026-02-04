module Core
module Services
  module ScheduledMessages
    class CreateService
        attr_reader :params, :user, :account

        def initialize(params:, user:, account:)
          @params = params
          @user = user
          @account = account
        end

        def perform
          validate_params!
          create_scheduled_message
        end

        private

        def create_scheduled_message
          scheduled_message = OttivScheduledMessage.new(scheduled_message_params)
          scheduled_message.account = account
          scheduled_message.creator = user
          scheduled_message.status = :scheduled
          scheduled_message.save!
          scheduled_message
        end

        def validate_params!
          raise ArgumentError, 'conversation_id is required' if params[:conversation_id].blank?
          raise ArgumentError, 'send_at must be in the future' if params[:send_at].present? && Time.parse(params[:send_at].to_s) <= Time.current
          raise ArgumentError, 'message_type is required' if params[:message_type].blank?
        end

        def scheduled_message_params
          permitted_params = params.permit(
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

          # Converter message_type de string para número se necessário
          if permitted_params[:message_type].present?
            message_type_str = permitted_params[:message_type].to_s
            case message_type_str
            when 'text', '0'
              permitted_params[:message_type] = 0
            when 'media', '1'
              permitted_params[:message_type] = 1
            when 'audio', '2'
              permitted_params[:message_type] = 2
            when 'quick_reply', '3'
              permitted_params[:message_type] = 3
            end
          end

          # Converter display_id para id real
          if permitted_params[:conversation_id].present?
            conversation = account.conversations.find_by(display_id: permitted_params[:conversation_id])
            if conversation
              permitted_params[:conversation_id] = conversation.id
            else
              raise ArgumentError, "Conversation with display_id #{permitted_params[:conversation_id]} not found"
            end
          end

          permitted_params
        end
      end
    end
  end
end

