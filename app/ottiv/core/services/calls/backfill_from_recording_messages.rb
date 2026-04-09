# frozen_string_literal: true

module Ottiv::Core
  module Services
    module Calls
      # Cria registros em +ottiv_calls+ a partir de mensagens privadas já existentes no Chatwoot
      # (gravações enviadas pelo serviço compress ou pelo +FetchCallRecordingJob+).
      class BackfillFromRecordingMessages
        # Compress (+processWavoipRecording+): "Gravação da chamada (ID: <whatsappCallId>)"
        COMPRESS_CONTENT_RE = /Gravação da chamada \(ID:\s*([^)]+)\)/i.freeze
        # FetchCallRecordingJob
        OTTIV_JOB_CONTENT_RE = /\[Ottiv\]\s*Gravação Wavoip \(\s*([^)]+)\s*\)/i.freeze
        FILENAME_GRAVACAO_RE = /\Agravacao_chamada_(.+)\.mp3\z/i.freeze
        FILENAME_WAVOIP_RE = /\Awavoip_recording_([^_]+)_/i.freeze

        def initialize(account:, dry_run: false, since: nil, until_time: nil)
          @account = account
          @dry_run = dry_run
          @since = since
          @until_time = until_time
        end

        # @return [Hash] estatísticas da execução
        def perform
          stats = {
            scanned: 0,
            created: 0,
            skipped_duplicate: 0,
            skipped_no_call_id: 0,
            skipped_no_audio: 0,
            errors: []
          }

          candidate_messages.find_each(batch_size: 200) do |message|
            stats[:scanned] += 1

            call_id = extract_provider_call_id(message)
            if call_id.blank?
              stats[:skipped_no_call_id] += 1
              next
            end

            if OttivCall.exists?(
              account_id: @account.id,
              provider: 'wavoip',
              provider_call_id: call_id
            )
              stats[:skipped_duplicate] += 1
              next
            end

            audio = first_audio_attachment(message)
            if audio.blank?
              stats[:skipped_no_audio] += 1
              next
            end

            if @dry_run
              stats[:created] += 1
              next
            end

            create_ottiv_call!(message, call_id, audio, stats)
          rescue StandardError => e
            stats[:errors] << { message_id: message.id, error: e.message }
          end

          stats
        end

        private

        def candidate_messages
          rel = Message
                .joins(:conversation)
                .where(conversations: { account_id: @account.id })
                .where(private: true, message_type: :outgoing)
                .where(
                  '(messages.content ILIKE ? OR messages.content ILIKE ?)',
                  '%Gravação da chamada (ID:%',
                  '%Gravação Wavoip%'
                )
                .preload(:attachments, :conversation)
                .order(:id)

          rel = rel.where('messages.created_at >= ?', @since) if @since.present?
          rel = rel.where('messages.created_at <= ?', @until_time) if @until_time.present?
          rel
        end

        def extract_provider_call_id(message)
          content = message.content.to_s
          m = content.match(COMPRESS_CONTENT_RE) || content.match(OTTIV_JOB_CONTENT_RE)
          return m[1].strip if m

          first_audio_attachment(message)&.then { |a| call_id_from_attachment_filename(a) }
        end

        def call_id_from_attachment_filename(attachment)
          return nil unless attachment.file.attached?

          name = attachment.file.filename.to_s
          m = name.match(FILENAME_GRAVACAO_RE) || name.match(FILENAME_WAVOIP_RE)
          m ? m[1].strip : nil
        end

        def first_audio_attachment(message)
          message.attachments.find(&:audio?)
        end

        def create_ottiv_call!(message, call_id, audio, stats)
          assignee_id = message.conversation&.assignee_id
          ended_at = message.created_at

          OttivCall.create!(
            account_id: @account.id,
            provider: 'wavoip',
            provider_call_id: call_id,
            conversation_id: message.conversation_id,
            user_id: assignee_id,
            status: 'recording_attached',
            started_at: ended_at,
            ended_at: ended_at,
            metadata: {
              'backfilled' => true,
              'backfilled_at' => Time.current.iso8601,
              'source_message_id' => message.id
            },
            recording_message_id: message.id,
            recording_attachment_id: audio.id
          )
          stats[:created] += 1
        end
      end
    end
  end
end
