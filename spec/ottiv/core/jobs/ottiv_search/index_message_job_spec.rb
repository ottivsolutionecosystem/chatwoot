# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ottiv::Core::Jobs::OttivSearch::IndexMessageJob, type: :job do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) do
    create(:message, account: account, conversation: conversation, content: 'Olá, teste')
  end

  let(:mock_client) { instance_double(Ottiv::Core::Services::OttivMeilisearchClient) }

  before do
    allow(Ottiv::Core::Services::OttivMeilisearchClient).to receive(:new).and_return(mock_client)
  end

  describe '#perform' do
    context 'when globally enabled and account has flag' do
      before do
        allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(true)
        allow_any_instance_of(Account).to receive(:ottiv_meilisearch_enabled?).and_return(true)
      end

      it 'indexes message with correct uid' do
        expected_uid = Ottiv::Core::Services::OttivIndexNaming.messages_uid(account.id)
        expect(mock_client).to receive(:add_or_update_documents) do |uid:, documents:|
          expect(uid).to eq(expected_uid)
          expect(documents.size).to eq(1)
          expect(documents.first[:id]).to eq("msg_#{message.id}")
          expect(documents.first[:content]).to eq('Olá, teste')
        end

        described_class.perform_now(message.id)
      end
    end

    context 'when globally disabled' do
      before do
        allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(false)
      end

      it 'does not index' do
        expect(mock_client).not_to receive(:add_or_update_documents)
        described_class.perform_now(message.id)
      end
    end

    context 'when message is activity type (not incoming/outgoing)' do
      let(:activity_message) do
        create(:message, account: account, conversation: conversation,
               message_type: Message.message_types[:activity])
      end

      before do
        allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(true)
        allow_any_instance_of(Account).to receive(:ottiv_meilisearch_enabled?).and_return(true)
      end

      it 'does not index activity messages' do
        expect(mock_client).not_to receive(:add_or_update_documents)
        described_class.perform_now(activity_message.id)
      end
    end

    it 'raises ActiveRecord::RecordNotFound for non-existent message' do
      expect { described_class.perform_now(0) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
