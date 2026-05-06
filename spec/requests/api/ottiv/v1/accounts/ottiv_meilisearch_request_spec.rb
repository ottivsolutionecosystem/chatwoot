# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Ottiv::V1::Accounts::OttivMeilisearch', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }

  shared_examples 'requires authentication' do |method, path|
    it 'returns unauthorized without auth' do
      send(method, path, as: :json)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/ottiv/v1/accounts/:account_id/ottiv_meilisearch/health' do
    let(:path) { "/api/ottiv/v1/accounts/#{account.id}/ottiv_meilisearch/health" }

    include_examples 'requires authentication', :get, '/api/ottiv/v1/accounts/0/ottiv_meilisearch/health'

    context 'when Meilisearch is available' do
      before do
        allow_any_instance_of(Ottiv::Core::Services::OttivMeilisearchClient)
          .to receive(:health).and_return({ 'status' => 'available' })
        allow_any_instance_of(Ottiv::Core::Services::OttivMeilisearchClient)
          .to receive(:get_index).and_return({ 'uid' => 'test', 'numberOfDocuments' => 0 })
      end

      it 'returns status available' do
        get path, headers: { api_access_token: user.access_token.token }
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['status']).to eq('available')
        expect(json).to have_key('globally_enabled')
        expect(json).to have_key('account_enabled')
        expect(json).to have_key('indexes')
      end
    end

    context 'when Meilisearch is unavailable' do
      before do
        allow_any_instance_of(Ottiv::Core::Services::OttivMeilisearchClient)
          .to receive(:health).and_raise(::Ottiv::Meilisearch::Error, 'Connection refused')
      end

      it 'returns 503' do
        get path, headers: { api_access_token: user.access_token.token }
        expect(response).to have_http_status(:service_unavailable)
        json = response.parsed_body
        expect(json['status']).to eq('unavailable')
      end
    end
  end

  describe 'POST /api/ottiv/v1/accounts/:account_id/ottiv_meilisearch/provision' do
    let(:path) { "/api/ottiv/v1/accounts/#{account.id}/ottiv_meilisearch/provision" }

    before do
      allow_any_instance_of(Ottiv::Core::Services::OttivIndexProvisioner)
        .to receive(:call).and_return({ messages: 1, contacts: 2 })
    end

    it 'provisions indexes and returns task info' do
      post path, headers: { api_access_token: user.access_token.token }, as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['status']).to eq('provisioned')
      expect(json).to have_key('tasks')
    end

    it 'returns 503 when Meilisearch is unavailable' do
      allow_any_instance_of(Ottiv::Core::Services::OttivIndexProvisioner)
        .to receive(:call).and_raise(::Ottiv::Meilisearch::Error, 'offline')
      post path, headers: { api_access_token: user.access_token.token }, as: :json
      expect(response).to have_http_status(:service_unavailable)
    end
  end

  describe 'POST /api/ottiv/v1/accounts/:account_id/ottiv_meilisearch/index_sample' do
    let(:path) { "/api/ottiv/v1/accounts/#{account.id}/ottiv_meilisearch/index_sample" }

    before do
      allow_any_instance_of(Ottiv::Core::Services::OttivIndexProvisioner)
        .to receive(:call).and_return({})
      allow_any_instance_of(Ottiv::Core::Services::OttivMeilisearchClient)
        .to receive(:add_or_update_documents).and_return({ 'taskUid' => 1 })
    end

    it 'indexes sample and returns counts' do
      post path,
           params: { contacts_limit: 5, messages_limit: 10 },
           headers: { api_access_token: user.access_token.token },
           as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['status']).to eq('indexed')
      expect(json).to have_key('contacts_indexed')
      expect(json).to have_key('messages_indexed')
    end
  end

  describe 'POST /api/ottiv/v1/accounts/:account_id/ottiv_meilisearch/test_search' do
    let(:path) { "/api/ottiv/v1/accounts/#{account.id}/ottiv_meilisearch/test_search" }

    before do
      allow_any_instance_of(Ottiv::Core::Services::OttivMeilisearchClient)
        .to receive(:search).and_return({
          'hits' => [{ 'contact_id' => 1, 'name' => 'José' }],
          'totalHits' => 1,
          'processingTimeMs' => 2
        })
    end

    it 'returns raw hits for contacts index' do
      post path,
           params: { q: 'jose', index: 'contacts' },
           headers: { api_access_token: user.access_token.token },
           as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to have_key('hits')
      expect(json['total']).to eq(1)
    end

    it 'returns error for invalid index' do
      post path,
           params: { q: 'jose', index: 'invalid' },
           headers: { api_access_token: user.access_token.token },
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/ottiv/v1/accounts/:account_id/ottiv_meilisearch/reindex_account' do
    let(:path) { "/api/ottiv/v1/accounts/#{account.id}/ottiv_meilisearch/reindex_account" }

    context 'when Meilisearch is globally enabled' do
      before do
        allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(true)
      end

      it 'enqueues BackfillAccountJob' do
        expect(Ottiv::Core::Jobs::OttivSearch::BackfillAccountJob)
          .to receive(:perform_later).with(account.id)

        post path, headers: { api_access_token: user.access_token.token }, as: :json
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['status']).to eq('enqueued')
      end
    end

    context 'when Meilisearch is globally disabled' do
      before do
        allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(false)
      end

      it 'returns unprocessable_entity' do
        post path, headers: { api_access_token: user.access_token.token }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
