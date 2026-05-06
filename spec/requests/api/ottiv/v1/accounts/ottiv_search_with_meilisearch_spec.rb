# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Ottiv::V1::Accounts::OttivSearch (adapter routing)', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, name: 'José da Silva') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }

  before do
    create(:inbox_member, user: user, inbox: inbox)
  end

  let(:path) { "/api/ottiv/v1/accounts/#{account.id}/ottiv_search" }
  let(:base_headers) { { api_access_token: user.access_token.token } }

  let(:postgres_result) do
    {
      results: [{ contact: { id: contact.id, name: 'José da Silva' }, conversations: [] }],
      messages: [],
      meta: { total_contacts: 1, total_conversations: 0, total_messages: 0, page: 1, per_page: 15 }
    }
  end

  describe 'adapter selection' do
    context 'when flag is disabled (default)' do
      it 'routes to SearchService (Postgres)' do
        expect_any_instance_of(Ottiv::Core::Services::SearchService)
          .to receive(:perform).and_return(postgres_result)
        expect_any_instance_of(Ottiv::Core::Services::OttivMeilisearchSearchService)
          .not_to receive(:perform)

        post path, params: { q: 'jose' }, headers: base_headers, as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when both global env and account flag are enabled' do
      before do
        allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(true)
        allow_any_instance_of(Account).to receive(:ottiv_meilisearch_enabled?).and_return(true)
      end

      it 'routes to OttivMeilisearchSearchService' do
        expect_any_instance_of(Ottiv::Core::Services::OttivMeilisearchSearchService)
          .to receive(:perform).and_return(postgres_result)
        expect_any_instance_of(Ottiv::Core::Services::SearchService)
          .not_to receive(:perform)

        post path, params: { q: 'jose' }, headers: base_headers, as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when global env is enabled but account flag is disabled' do
      before do
        allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(true)
        allow_any_instance_of(Account).to receive(:ottiv_meilisearch_enabled?).and_return(false)
      end

      it 'routes to SearchService (Postgres)' do
        expect_any_instance_of(Ottiv::Core::Services::SearchService)
          .to receive(:perform).and_return(postgres_result)

        post path, params: { q: 'jose' }, headers: base_headers, as: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'fallback on Meilisearch error' do
    before do
      allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(true)
      allow_any_instance_of(Account).to receive(:ottiv_meilisearch_enabled?).and_return(true)
      allow_any_instance_of(Ottiv::Core::Services::OttivMeilisearchClient)
        .to receive(:multi_search).and_raise(::Ottiv::Meilisearch::Error, 'timeout')
    end

    it 'falls back to SearchService and returns 200' do
      expect_any_instance_of(Ottiv::Core::Services::SearchService)
        .to receive(:perform).and_return(postgres_result)

      post path, params: { q: 'jose' }, headers: base_headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'payload structure' do
    before do
      allow_any_instance_of(Ottiv::Core::Services::SearchService)
        .to receive(:perform).and_return(postgres_result)
    end

    it 'returns results, messages, and meta keys' do
      post path, params: { q: 'jose' }, headers: base_headers, as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to have_key('payload')
      payload = json['payload']
      expect(payload).to have_key('results')
      expect(payload).to have_key('messages')
      expect(payload).to have_key('meta')
    end
  end
end
