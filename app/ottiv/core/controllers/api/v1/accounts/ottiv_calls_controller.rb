# frozen_string_literal: true

module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class OttivCallsController < ::Api::V1::Accounts::BaseController
            before_action :authorize_ottiv_call_sync!, only: [:sync]
            before_action :authorize_sync_conversation!, only: [:sync]

            def sync
              service = ::Ottiv::Core::Services::Calls::UpsertFromClientEvent.new(
                account: Current.account,
                user: Current.user,
                params: sync_params
              )
              call = service.perform
              render json: { ottiv_call: ottiv_call_payload(call) }, status: :ok
            rescue ArgumentError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            private

            def authorize_ottiv_call_sync!
              authorize ::OttivCall, :sync?
            end

            def authorize_sync_conversation!
              cid = params[:conversation_id]
              return if cid.blank?

              conv = Current.account.conversations.find_by(display_id: cid) ||
                     Current.account.conversations.find_by(id: cid)
              unless conv
                render json: { error: 'conversation not found' }, status: :not_found
                return
              end

              authorize conv, :show?
            end

            def sync_params
              base = params.permit(
                :event,
                :provider,
                :provider_call_id,
                :conversation_id,
                :occurred_at,
                :direction,
                :peer_phone,
                :duration_seconds
              )
              h = base.to_unsafe_h
              if params[:metadata].present?
                h['metadata'] = case params[:metadata]
                                when ActionController::Parameters
                                  params[:metadata].permit!.to_h
                                when Hash
                                  params[:metadata].stringify_keys
                                else
                                  {}
                                end
              end
              h
            end

            def ottiv_call_payload(call)
              {
                id: call.id,
                account_id: call.account_id,
                provider: call.provider,
                provider_call_id: call.provider_call_id,
                conversation_id: call.conversation_id,
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
                metadata: call.metadata
              }
            end
          end
        end
      end
    end
  end
end
