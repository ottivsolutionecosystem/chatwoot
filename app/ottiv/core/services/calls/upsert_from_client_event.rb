# frozen_string_literal: true

module Ottiv::Core
  module Services
    module Calls
      class UpsertFromClientEvent
        END_EVENTS = %w[call_ended call_completed].freeze

        def initialize(account:, user:, params:)
          @account = account
          @user = user
          @params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.deep_stringify_keys
        end

        def perform
          validate!

          ottiv_call = OttivCall.find_or_initialize_by(
            account_id: @account.id,
            provider: @params['provider'],
            provider_call_id: @params['provider_call_id']
          )

          conversation = resolve_conversation
          merge_attributes!(ottiv_call, conversation)
          ottiv_call.save!

          enqueue_recording_job_if_needed(ottiv_call, conversation)

          ottiv_call
        end

        private

        def validate!
          raise ArgumentError, 'provider is required' if @params['provider'].blank?
          raise ArgumentError, 'provider_call_id is required' if @params['provider_call_id'].blank?
          raise ArgumentError, 'event is required' if @params['event'].blank?
        end

        def normalized_event
          @params['event'].to_s.downcase
        end

        def end_event?
          END_EVENTS.include?(normalized_event)
        end

        def resolve_conversation
          cid = @params['conversation_id']
          return nil if cid.blank?

          @account.conversations.find_by(display_id: cid) ||
            @account.conversations.find_by(id: cid)
        end

        def merge_attributes!(ottiv_call, conversation)
          ottiv_call.user_id = conversation.assignee_id if conversation
          ottiv_call.conversation_id = conversation.id if conversation
          ottiv_call.direction = @params['direction'] if @params['direction'].present?

          if @params['metadata'].present?
            meta = ottiv_call.metadata.is_a?(Hash) ? ottiv_call.metadata : {}
            ottiv_call.metadata = meta.merge(@params['metadata'].stringify_keys)
          end

          if @params['duration_seconds'].present?
            ottiv_call.duration_seconds = @params['duration_seconds'].to_i
          end

          if @params['peer_phone'].present?
            meta = ottiv_call.metadata.is_a?(Hash) ? ottiv_call.metadata : {}
            ottiv_call.metadata = meta.merge('peer_phone' => @params['peer_phone'].to_s)
          end

          occurred = parse_time(@params['occurred_at'])

          case normalized_event
          when 'call_started', 'call_accepted'
            ottiv_call.started_at ||= occurred || Time.current
          when *END_EVENTS
            ottiv_call.ended_at = occurred || Time.current
            if ottiv_call.recording_message_id.present?
              ottiv_call.status = 'recording_attached'
            elsif conversation.present?
              ottiv_call.status = 'pending_recording'
            end
          when 'call_rejected', 'call_error'
            ottiv_call.ended_at ||= occurred || Time.current
          end
        end

        def parse_time(value)
          return nil if value.blank?

          Time.zone.parse(value.to_s)
        end

        def enqueue_recording_job_if_needed(ottiv_call, conversation)
          return unless end_event?
          return if conversation.blank?
          return if ottiv_call.recording_message_id.present?
          return if ottiv_call.recording_job_enqueued_at.present?

          delay_seconds = ENV.fetch('WAVOIP_RECORDING_DELAY', '300').to_i
          ottiv_call.update_columns(
            recording_job_enqueued_at: Time.current,
            updated_at: Time.current
          )

          Ottiv::Core::Jobs::FetchCallRecordingJob
            .set(wait: delay_seconds.seconds)
            .perform_later(ottiv_call.id)
        end
      end
    end
  end
end
