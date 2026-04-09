# frozen_string_literal: true

module Ottiv::Core
  module Jobs
    class ReconcilePendingCallRecordingsJob < ApplicationJob
      queue_as :ottiv_core_scheduled_jobs

      STALE_AFTER = 15.minutes
      MAX_RECONCILE_ENQUEUES = 8

      def perform
        OttivCall.pending_recording_stale(STALE_AFTER.ago).find_each do |call|
          meta = call.metadata || {}
          n = meta['reconcile_enqueues'].to_i
          if n >= MAX_RECONCILE_ENQUEUES
            call.update!(
              status: 'recording_failed',
              recording_failure_reason: 'reconcile_max_attempts',
              metadata: meta.merge('reconcile_enqueues' => n)
            )
            next
          end

          call.update!(
            metadata: meta.merge('reconcile_enqueues' => n + 1),
            updated_at: Time.current
          )
          FetchCallRecordingJob.perform_later(call.id)
        end
      end
    end
  end
end
