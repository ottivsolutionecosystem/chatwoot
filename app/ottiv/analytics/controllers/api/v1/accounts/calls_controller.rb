# frozen_string_literal: true

module Ottiv::Analytics
  module Controllers
    module Api
      module V1
        module Accounts
          class CallsController < ::Api::V1::Accounts::BaseController
            before_action :authorize_ottiv_calls_index!, only: [:index]
            before_action :authorize_ottiv_calls_summary!, only: [:summary]

            def index
              query = ::Ottiv::Analytics::Queries::OttivCallsQuery.new(
                account: Current.account,
                params: filter_params
              )
              page = (params[:page] || 1).to_i
              per = [[(params[:per_page] || 20).to_i, 1].max, 100].min
              calls = query.relation.includes(:conversation, :user).page(page).per(per)

              render json: {
                data: calls.map { |c| serialize_call(c) },
                meta: {
                  current_page: calls.current_page,
                  total_pages: calls.total_pages,
                  total_count: calls.total_count
                }
              }
            end

            def summary
              query = ::Ottiv::Analytics::Queries::OttivCallsQuery.new(
                account: Current.account,
                params: filter_params
              )
              render json: {
                by_status: query.summary_by_status,
                by_day: query.summary_by_day.transform_keys { |k| k.respond_to?(:iso8601) ? k.iso8601 : k.to_s },
                by_user_id: query.summary_by_user_id
              }
            end

            private

            def authorize_ottiv_calls_index!
              authorize ::OttivCall, :index?
            end

            def authorize_ottiv_calls_summary!
              authorize ::OttivCall, :summary?
            end

            def filter_params
              params.permit(:provider, :status, :conversation_id, :from, :to, :user_id, :agent_id).to_h.symbolize_keys
            end

            def serialize_call(call)
              recording = recording_payload(call)

              {
                id: call.id,
                provider: call.provider,
                provider_call_id: call.provider_call_id,
                conversation_id: call.conversation&.display_id,
                conversation_internal_id: call.conversation_id,
                user_id: call.user_id,
                assignee_id: call.user_id,
                direction: call.direction,
                status: call.status,
                started_at: call.started_at,
                ended_at: call.ended_at,
                duration_seconds: call.duration_seconds,
                recording_message_id: call.recording_message_id,
                recording_attachment_id: call.recording_attachment_id,
                recording_job_enqueued_at: call.recording_job_enqueued_at,
                recording_failure_reason: call.recording_failure_reason,
                metadata: call.metadata,
                recording: recording
              }
            end

            def recording_payload(call)
              return nil if call.recording_message_id.blank?

              message = Current.account.messages.find_by(id: call.recording_message_id)
              return { state: 'missing_message' } if message.blank?

              message.attachments.load
              {
                state: 'attached',
                attachments: message.attachments.filter_map { |a| attachment_for_recording_api(a) }
              }
            end

            # URLs absolutas no host do Chatwoot (Active Storage), para o browser não depender do MinIO/S3.
            def attachment_for_recording_api(attachment)
              data = attachment.push_event_data
              return nil if data.blank?

              return data unless attachment.file.attached?

              data = data.deep_dup
              blob = attachment.file.blob
              data[:data_url] = absolute_rails_blob_url(blob, disposition: :inline)
              data[:download_url] = absolute_rails_blob_url(blob, disposition: :attachment)
              data
            end

            def absolute_rails_blob_url(blob, disposition: :inline)
              path = Rails.application.routes.url_helpers.rails_blob_path(
                blob,
                disposition: disposition,
                only_path: true
              )
              "#{recording_attachment_url_base}#{path}"
            end

            # Base para <audio src> / links consumidos pelo frontend Auttus (mesma origem que VITE_CHATWOOT_URL).
            # CHATWOOT_PUBLIC_BASE_URL tem prioridade sobre o Host da requisição (evita localhost quando o client usa proxy).
            def recording_attachment_url_base
              explicit = ENV['CHATWOOT_PUBLIC_BASE_URL'].presence || ENV['ACTIVE_STORAGE_PUBLIC_BASE_URL'].presence
              return explicit.to_s.chomp('/') if explicit.present?

              if respond_to?(:request) && request.present?
                return request.base_url.chomp('/')
              end

              ottiv_public_app_url_base
            end

            def ottiv_public_app_url_base
              raw = ENV['FRONTEND_URL'].presence
              return 'http://localhost:3000' if raw.blank?

              uri = URI.parse(raw.include?('://') ? raw : "https://#{raw}")
              base = "#{uri.scheme}://#{uri.host}"
              base += ":#{uri.port}" if uri.port && uri.port != uri.default_port
              base
            rescue URI::InvalidURIError
              'http://localhost:3000'
            end
          end
        end
      end
    end
  end
end
