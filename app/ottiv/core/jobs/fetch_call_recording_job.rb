# frozen_string_literal: true

module Ottiv::Core
  module Jobs
    class FetchCallRecordingJob < ApplicationJob
      queue_as :ottiv_core_low

      retry_on ::Ottiv::Core::RecordingNotReadyError, wait: :polynomially_longer, attempts: 25
      retry_on Down::Error, wait: :polynomially_longer, attempts: 8

      def perform(ottiv_call_id)
        call = OttivCall.lock.find_by(id: ottiv_call_id)
        return if call.blank?
        return if call.recording_message_id.present?

        conversation = call.conversation
        account = call.account

        if conversation.blank?
          mark_failed(call, 'conversation_missing')
          return
        end

        user = conversation.assignee || call.user || account.users.first
        if user.blank?
          mark_failed(call, 'user_missing')
          return
        end

        url = recording_url(call)
        downloaded = Down.download(url)

        classified = classify_wavoip_body(downloaded)
        if classified == :pending
          raise ::Ottiv::Core::RecordingNotReadyError, 'RECORDING'
        elsif classified.is_a?(Array) && classified[0] == :unexpected_json
          mark_failed(call, classified[1])
          return
        end

        ActiveRecord::Base.transaction do
          content = "[Ottiv] Gravação Wavoip (#{call.provider_call_id})"
          params = ActionController::Parameters.new(
            content: content,
            message_type: 'outgoing',
            private: true,
            content_type: 'text'
          )
          message = Messages::MessageBuilder.new(user, conversation, params).perform

          attachment = message.attachments.create!(
            account_id: message.account_id,
            file_type: :audio
          )

          downloaded.rewind if downloaded.respond_to?(:rewind)

          attachment.file.attach(
            io: downloaded,
            filename: filename_for(call, downloaded),
            content_type: downloaded.content_type.presence || 'audio/mpeg'
          )
          attachment.save!

          call.update!(
            recording_message_id: message.id,
            recording_attachment_id: attachment.id,
            status: 'recording_attached',
            recording_failure_reason: nil,
            user_id: conversation.assignee_id
          )
        end
      rescue Down::Error
        raise
      rescue ::Ottiv::Core::RecordingNotReadyError
        raise
      rescue StandardError => e
        mark_failed(call, e.message) if call
        Rails.logger.error("[FetchCallRecordingJob] #{e.class}: #{e.message}\n#{e.backtrace&.first(8)&.join("\n")}")
      end

      private

      def recording_url(call)
        base = ENV.fetch('WAVOIP_RECORDING_URL', 'https://storage.wavoip.com').to_s.chomp('/')
        "#{base}/#{call.provider_call_id}"
      end

      # :pending — Wavoip ainda processando; :binary — tratar como arquivo de áudio;
      # [:unexpected_json, msg] — JSON que não é RECORDING (erro definitivo)
      def classify_wavoip_body(file)
        body = file.read
        file.rewind if file.respond_to?(:rewind)
        return :binary if body.blank?
        return :binary unless body.lstrip.start_with?('{')

        json = JSON.parse(body)
        file.rewind if file.respond_to?(:rewind)
        return :pending if json['status'].to_s == 'RECORDING'

        [:unexpected_json, "wavoip_json:#{json.to_json.truncate(300)}"]
      rescue JSON::ParserError
        file.rewind if file.respond_to?(:rewind)
        :binary
      end

      def filename_for(call, downloaded)
        if downloaded.respond_to?(:original_filename) && downloaded.original_filename.present?
          downloaded.original_filename
        else
          "wavoip_recording_#{call.provider_call_id}.mp3"
        end
      end

      def mark_failed(call, reason)
        call.update!(
          status: 'recording_failed',
          recording_failure_reason: reason.to_s.truncate(500)
        )
      end
    end
  end
end
