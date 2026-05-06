# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ottiv::Core::Jobs::OttivSearch::RemoveDocumentJob, type: :job do
  let(:mock_client) { instance_double(Ottiv::Core::Services::OttivMeilisearchClient) }

  before do
    allow(Ottiv::Core::Services::OttivMeilisearchClient).to receive(:new).and_return(mock_client)
    allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(true)
  end

  describe '#perform' do
    context 'with doc_id' do
      it 'calls delete_document with uid and doc_id' do
        expect(mock_client).to receive(:delete_document).with(uid: 'ottiv_messages_acc_1', doc_id: 'msg_42')
        described_class.perform_now(uid: 'ottiv_messages_acc_1', doc_id: 'msg_42')
      end
    end

    context 'with filter' do
      it 'calls delete_documents_by_filter' do
        expect(mock_client).to receive(:delete_documents_by_filter)
          .with(uid: 'ottiv_messages_acc_1', filter: 'conversation_id = 5')
        described_class.perform_now(uid: 'ottiv_messages_acc_1', filter: 'conversation_id = 5')
      end
    end

    context 'when globally disabled' do
      before { allow(::Ottiv::Meilisearch).to receive(:globally_enabled?).and_return(false) }

      it 'does nothing' do
        expect(mock_client).not_to receive(:delete_document)
        expect(mock_client).not_to receive(:delete_documents_by_filter)
        described_class.perform_now(uid: 'ottiv_messages_acc_1', doc_id: 'msg_1')
      end
    end
  end
end
