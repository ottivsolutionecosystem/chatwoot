# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Ottiv::V1::Accounts::OttivCalls', type: :request do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    create(:inbox_member, user: user, inbox: conversation.inbox)
  end

  describe 'POST /api/ottiv/v1/accounts/:account_id/ottiv_calls/sync' do
    before do
      conversation.update!(assignee: user)
    end

    it 'returns unauthorized without auth' do
      post "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/sync",
           params: { event: 'call_ended', provider: 'wavoip', provider_call_id: 'c1', conversation_id: conversation.display_id },
           as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 when params are invalid' do
      post "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/sync",
           params: { event: 'call_ended' },
           headers: user.create_new_auth_token,
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'enqueues FetchCallRecordingJob when call_ended includes conversation' do
      expect do
        post "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/sync",
             params: {
               event: 'call_ended',
               provider: 'wavoip',
               provider_call_id: 'call-xyz-1',
               conversation_id: conversation.display_id
             },
             headers: user.create_new_auth_token,
             as: :json
      end.to have_enqueued_job(Ottiv::Core::Jobs::FetchCallRecordingJob)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['ottiv_call']['status']).to eq('pending_recording')
      expect(body['ottiv_call']['provider_call_id']).to eq('call-xyz-1')
      expect(body['ottiv_call']['user_id']).to eq(user.id)
      expect(body['ottiv_call']['assignee_id']).to eq(user.id)
    end

    it 'returns not_found when conversation_id does not exist' do
      post "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/sync",
           params: {
             event: 'call_ended',
             provider: 'wavoip',
             provider_call_id: 'call-missing-conv',
             conversation_id: 9_999_999
           },
           headers: user.create_new_auth_token,
           as: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns unauthorized when agent cannot access the conversation inbox' do
      other_agent = create(:user, account: account, role: :agent)

      post "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/sync",
           params: {
             event: 'call_ended',
             provider: 'wavoip',
             provider_call_id: 'call-no-inbox',
             conversation_id: conversation.display_id
           },
           headers: other_agent.create_new_auth_token,
           as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'persists peer_phone in metadata and direction from payload' do
      post "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/sync",
           params: {
             event: 'call_ended',
             provider: 'wavoip',
             provider_call_id: 'call-meta-1',
             conversation_id: conversation.display_id,
             direction: 'outgoing',
             peer_phone: '+5511999999999',
             duration_seconds: 42
           },
           headers: user.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      oc = OttivCall.find_by(provider_call_id: 'call-meta-1')
      expect(oc.direction).to eq('outgoing')
      expect(oc.duration_seconds).to eq(42)
      expect(oc.metadata['peer_phone']).to eq('+5511999999999')
      expect(oc.user_id).to eq(user.id)
    end

    it 'does not enqueue job twice for the same provider_call_id' do
      headers = user.create_new_auth_token
      params = {
        event: 'call_ended',
        provider: 'wavoip',
        provider_call_id: 'call-dedupe',
        conversation_id: conversation.display_id
      }
      post "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/sync", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)

      expect do
        post "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/sync", params: params, headers: headers, as: :json
      end.not_to have_enqueued_job(Ottiv::Core::Jobs::FetchCallRecordingJob)
    end
  end

  describe 'GET /api/ottiv/v1/accounts/:account_id/ottiv_calls' do
    it 'returns paginated ottiv_calls' do
      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 'r1',
        conversation: conversation,
        user: user,
        status: 'pending_recording'
      )

      get "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls",
          headers: user.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      data = response.parsed_body['data']
      expect(data.length).to eq(1)
      expect(data.first['provider_call_id']).to eq('r1')
      expect(data.first['assignee_id']).to eq(user.id)
      expect(data.first['assignee_id']).to eq(data.first['user_id'])
    end

    it 'returns recording data_url as absolute Chatwoot Active Storage URL' do
      msg = create(
        :message,
        account: account,
        conversation: conversation,
        message_type: :outgoing,
        sender: user,
        private: true,
        content: 'Gravação'
      )
      att = msg.attachments.create!(account_id: account.id, file_type: :audio)
      att.file.attach(
        io: StringIO.new("fake-audio-#{SecureRandom.hex(4)}"),
        filename: 'rec.mp3',
        content_type: 'audio/mpeg'
      )
      att.save!

      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 'with-rec-url',
        conversation: conversation,
        user: user,
        status: 'recording_attached',
        recording_message_id: msg.id,
        recording_attachment_id: att.id
      )

      get "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls",
          headers: user.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      row = response.parsed_body['data'].first
      expect(row['recording']['state']).to eq('attached')
      att_json = row['recording']['attachments'].first
      expect(att_json['data_url']).to match(%r{\Ahttps?://[^/]+/rails/active_storage/})
      expect(att_json['download_url']).to match(%r{\Ahttps?://[^/]+/rails/active_storage/})
    end

    it 'filters by user_id (agent)' do
      other = create(:user, account: account, role: :agent)
      create(:inbox_member, user: other, inbox: conversation.inbox)

      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 'mine',
        conversation: conversation,
        user: user,
        status: 'recording_attached'
      )
      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 'theirs',
        conversation: conversation,
        user: other,
        status: 'recording_attached'
      )

      get "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls",
          params: { user_id: user.id },
          headers: user.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body['data'].map { |row| row['provider_call_id'] }
      expect(ids).to eq(['mine'])
    end

    it 'accepts agent_id as alias for user_id filter' do
      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 'a1',
        conversation: conversation,
        user: user,
        status: 'recording_attached'
      )

      get "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls",
          params: { agent_id: user.id },
          headers: user.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data'].length).to eq(1)
    end

    it 'orders by created_at descending' do
      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 'older',
        conversation: conversation,
        user: user,
        status: 'recording_attached',
        created_at: 2.days.ago
      )
      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 'newer',
        conversation: conversation,
        user: user,
        status: 'recording_attached',
        created_at: 1.hour.ago
      )

      get "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls",
          headers: user.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body['data'].map { |row| row['provider_call_id'] }
      expect(ids).to eq(%w[newer older])
    end
  end

  describe 'GET /api/ottiv/v1/accounts/:account_id/ottiv_calls/summary' do
    it 'returns aggregates' do
      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 's1',
        status: 'pending_recording'
      )

      get "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/summary",
          headers: user.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['by_status']).to include('pending_recording' => 1)
    end

    it 'returns counts grouped by user_id' do
      other = create(:user, account: account, role: :agent)

      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 'u1a',
        user: user,
        status: 'recording_attached'
      )
      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 'u1b',
        user: user,
        status: 'recording_attached'
      )
      OttivCall.create!(
        account: account,
        provider: 'wavoip',
        provider_call_id: 'no-user',
        user: nil,
        status: 'recording_attached'
      )

      get "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/summary",
          headers: user.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      by_user = response.parsed_body['by_user_id']
      expect(by_user[user.id.to_s]).to eq(2)
      expect(by_user['null']).to eq(1)
    end
  end
end
