module Ottiv::Core
module Services
  module ScheduledMessages
    class SendService
        attr_reader :scheduled_message

        def initialize(scheduled_message)
          @scheduled_message = scheduled_message
        end

        def perform
          ActiveRecord::Base.transaction do
            message = send_message
            update_scheduled_message_status
            create_next_occurrence_if_recurrent
            create_occurrence_record(message)
            message
          end
        rescue StandardError => e
          handle_error(e)
          raise e
        end

        private

        def send_message
          conversation = scheduled_message.conversation
          user = scheduled_message.creator

          message_params = build_message_params
          builder = Messages::MessageBuilder.new(user, conversation, message_params)
          message = builder.perform

          # Process attachments from URLs (audio_url or media_url)
          process_attachments_from_urls(message)

          # Mark message as scheduled
          message.update!(
            additional_attributes: (message.additional_attributes || {}).merge(is_scheduled: true)
          )

          message
        end

        def build_message_params
          params = ActionController::Parameters.new({
            content: scheduled_message.content,
            message_type: 'outgoing',
            private: false
          })

          # Add content_type based on message_type
          case scheduled_message.message_type
          when 'text'
            params[:content_type] = :text
          when 'media'
            params[:content_type] = :text
            # Media URL will be processed in process_attachments_from_urls
          when 'audio'
            params[:content_type] = :text
            # Audio URL will be processed in process_attachments_from_urls
          when 'quick_reply'
            params[:content_type] = :text
            # Quick reply handling would be done via content_attributes
          end

          params
        end

        def process_attachments_from_urls(message)
          # Process audio_url if present
          if scheduled_message.audio_url.present? && scheduled_message.audio_url != 'pending_upload'
            create_attachment_from_url(message, scheduled_message.audio_url, :audio)
          end

          # Process media_url if present
          if scheduled_message.media_url.present? && scheduled_message.media_url != 'pending_upload'
            # Detect file type from URL or content type
            create_attachment_from_url(message, scheduled_message.media_url, nil)
          end
        end

        def create_attachment_from_url(message, file_url, file_type = nil)
          return if file_url.blank? || file_url == 'pending_upload'

          begin
            # Download file from URL
            downloaded_file = Down.download(file_url)

            # Detect file type if not provided
            detected_file_type = file_type || detect_file_type_from_content_type(downloaded_file.content_type)

            # Create attachment
            attachment = message.attachments.new(
              account_id: message.account_id,
              file_type: detected_file_type
            )

            # Attach the downloaded file
            attachment.file.attach(
              io: downloaded_file,
              filename: downloaded_file.original_filename || "attachment.#{detected_file_type}",
              content_type: downloaded_file.content_type
            )

            attachment.save!

            Rails.logger.info "✅ [ScheduledMessages] Attachment criado para mensagem #{message.id} a partir de URL: #{file_url} (tipo: #{detected_file_type})"
          rescue StandardError => e
            Rails.logger.error "❌ [ScheduledMessages] Erro ao criar attachment a partir de URL #{file_url}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            # Não falhar o envio da mensagem se o attachment falhar
          end
        end

        def detect_file_type_from_content_type(content_type)
          return :image if content_type&.start_with?('image/')
          return :video if content_type&.start_with?('video/')
          return :audio if content_type&.start_with?('audio/')
            
          # Default to image for media_url if type cannot be determined
          :image
        end

        def update_scheduled_message_status
          scheduled_message.mark_as_sent!
        end

        def create_next_occurrence_if_recurrent
          return unless scheduled_message.has_recurrence?

          next_send_at = calculate_next_send_at
          return if next_send_at.nil?

          # Create new scheduled message for next occurrence
          OttivScheduledMessage.create!(
            title: scheduled_message.title,
            message_type: scheduled_message.message_type,
            content: scheduled_message.content,
            media_url: scheduled_message.media_url,
            audio_url: scheduled_message.audio_url,
            quick_reply_id: scheduled_message.quick_reply_id,
            account_id: scheduled_message.account_id,
            conversation_id: scheduled_message.conversation_id,
            contact_id: scheduled_message.contact_id,
            send_at: next_send_at,
            timezone: scheduled_message.timezone,
            recurrence: scheduled_message.recurrence,
            status: :scheduled,
            created_by: scheduled_message.created_by
          )
        end

        def calculate_next_send_at
          current_send_at = @scheduled_message.send_at
            
          case @scheduled_message.recurrence.to_sym
          when :daily
            current_send_at + 1.day
          when :weekly
            current_send_at + 1.week
          when :biweekly
            current_send_at + 2.weeks
          when :monthly
            current_send_at + 1.month
          when :quarterly
            current_send_at + 3.months
          when :semiannual
            current_send_at + 6.months
          when :annual
            current_send_at + 1.year
          else
            nil # no_recurrence
          end
        end

        def create_occurrence_record(message)
          scheduled_message.ottiv_scheduled_message_occurrences.create!(
            sent_at: Time.current,
            status: :sent
          )
        end

        def handle_error(error)
          scheduled_message.mark_as_failed!(error.message)
        end
      end
    end
  end
end

