# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ottiv::Core::Services::OttivMeilisearchSearchService, type: :service do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, name: 'José da Silva', phone_number: '+5544999990000') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, conversation: conversation, content: 'Olá José') }

  before do
    create(:inbox_member, user: user, inbox: inbox)
    allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(true)
    allow_any_instance_of(Account).to receive(:ottiv_meilisearch_enabled?).and_return(true)
  end

  let(:mock_client) { instance_double(Ottiv::Core::Services::OttivMeilisearchClient) }

  before do
    allow(Ottiv::Core::Services::OttivMeilisearchClient).to receive(:new).and_return(mock_client)
  end

  subject(:service) do
    described_class.new(
      current_user: user,
      current_account: account,
      params: { q: 'jose', page: 1, status: 'all', sort_by: 'last_activity_at_desc' }.with_indifferent_access
    )
  end

  describe '#perform' do
    let(:contacts_meili_result) do
      {
        'hits' => [{ 'contact_id' => contact.id }],
        'totalHits' => 1,
        'estimatedTotalHits' => 1
      }
    end

    let(:messages_meili_result) do
      {
        'hits' => [{ 'message_id' => message.id }],
        'totalHits' => 1,
        'estimatedTotalHits' => 1
      }
    end

    before do
      allow(mock_client).to receive(:multi_search).and_return({
        'results' => [contacts_meili_result, messages_meili_result]
      })
      # garante que dados existem
      message
      conversation
    end

    it 'returns results, messages, and meta' do
      result = service.perform
      expect(result).to have_key(:results)
      expect(result).to have_key(:messages)
      expect(result).to have_key(:meta)
    end

    it 'meta includes required keys' do
      result = service.perform
      meta = result[:meta]
      expect(meta).to have_key(:total_contacts)
      expect(meta).to have_key(:total_conversations)
      expect(meta).to have_key(:total_messages)
      expect(meta).to have_key(:page)
      expect(meta).to have_key(:per_page)
    end

    it 'meta total_contacts reflects Meilisearch totalHits' do
      result = service.perform
      expect(result[:meta][:total_contacts]).to eq(1)
    end

    it 'meta page is correct' do
      result = service.perform
      expect(result[:meta][:page]).to eq(1)
    end

    context 'when Meilisearch raises an error' do
      before do
        allow(mock_client).to receive(:multi_search).and_raise(::Ottiv::Meilisearch::Error, 'timeout')
        allow_any_instance_of(Ottiv::Core::Services::SearchService).to receive(:perform).and_return({
          results: [], messages: [],
          meta: { total_contacts: 0, total_conversations: 0, total_messages: 0, page: 1, per_page: 15 }
        })
      end

      it 'falls back to SearchService' do
        expect_any_instance_of(Ottiv::Core::Services::SearchService).to receive(:perform)
        service.perform
      end

      it 'returns valid result structure even after fallback' do
        result = service.perform
        expect(result).to have_key(:results)
        expect(result).to have_key(:messages)
        expect(result).to have_key(:meta)
      end
    end

    context 'with status filter' do
      subject(:filtered_service) do
        described_class.new(
          current_user: user,
          current_account: account,
          params: { q: 'jose', page: 1, status: 'open', sort_by: 'last_activity_at_desc' }.with_indifferent_access
        )
      end

      it 'includes status filter in Meilisearch query' do
        expect(mock_client).to receive(:multi_search) do |queries:|
          msg_query = queries.find { |q| q[:indexUid].include?('messages') }
          expect(msg_query[:filter]).to include('conversation_status = open')
          { 'results' => [contacts_meili_result, messages_meili_result] }
        end

        filtered_service.perform
      end
    end

    context 'with assignee_type=me filter' do
      subject(:filtered_service) do
        described_class.new(
          current_user: user,
          current_account: account,
          params: {
            q: 'jose', page: 1, status: 'all',
            sort_by: 'last_activity_at_desc', assignee_type: 'me'
          }.with_indifferent_access
        )
      end

      it 'includes assignee_id filter in messages query' do
        expect(mock_client).to receive(:multi_search) do |queries:|
          msg_query = queries.find { |q| q[:indexUid].include?('messages') }
          expect(msg_query[:filter]).to include("conversation_assignee_id = #{user.id}")
          { 'results' => [contacts_meili_result, messages_meili_result] }
        end

        filtered_service.perform
      end
    end

    context 'when q is blank' do
      subject(:blank_service) do
        described_class.new(
          current_user: user,
          current_account: account,
          params: { q: '', page: 1 }.with_indifferent_access
        )
      end

      it 'falls back to SearchService (blank q)' do
        expect_any_instance_of(Ottiv::Core::Services::SearchService).to receive(:perform).and_return({
          results: [], messages: [],
          meta: { total_contacts: 0, total_conversations: 0, total_messages: 0, page: 1, per_page: 15 }
        })
        blank_service.perform
      end
    end
  end
end
