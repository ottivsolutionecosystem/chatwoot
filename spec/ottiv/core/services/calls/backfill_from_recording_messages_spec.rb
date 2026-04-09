# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ottiv::Core::Services::Calls::BackfillFromRecordingMessages do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    create(:inbox_member, user: user, inbox: conversation.inbox)
    conversation.update!(assignee: user)
  end

  def build_private_recording_message(content:, filename: 'gravacao_chamada_abc123.mp3')
    msg = create(
      :message,
      account: account,
      conversation: conversation,
      message_type: :outgoing,
      sender: user,
      private: true,
      content: content
    )
    att = msg.attachments.create!(account_id: account.id, file_type: :audio)
    att.file.attach(
      io: StringIO.new("fake mp3 #{SecureRandom.hex(4)}"),
      filename: filename,
      content_type: 'audio/mpeg'
    )
    att.save!
    msg.reload
  end

  describe '#perform' do
    it 'cria ottiv_call a partir do texto do compress' do
      build_private_recording_message(
        content: 'Gravação da chamada (ID: wa-999)',
        filename: 'gravacao_chamada_wa-999.mp3'
      )

      stats = described_class.new(account: account).perform

      expect(stats[:created]).to eq(1)
      oc = OttivCall.find_by(provider_call_id: 'wa-999')
      expect(oc).to be_present
      expect(oc.status).to eq('recording_attached')
      expect(oc.metadata['backfilled']).to be true
      expect(oc.user_id).to eq(conversation.assignee_id)
    end

    it 'usa assignee da conversa, não o remetente da mensagem' do
      other = create(:user, account: account, role: :agent)
      create(:inbox_member, user: other, inbox: conversation.inbox)
      conversation.update!(assignee: other)

      build_private_recording_message(
        content: 'Gravação da chamada (ID: wa-assignee)',
        filename: 'gravacao_chamada_wa-assignee.mp3'
      )

      described_class.new(account: account).perform
      oc = OttivCall.find_by(provider_call_id: 'wa-assignee')
      expect(oc.user_id).to eq(other.id)
    end

    it 'cria ottiv_call a partir do texto do job Ottiv' do
      build_private_recording_message(
        content: '[Ottiv] Gravação Wavoip (job-1)',
        filename: 'wavoip_recording_job-1_xyz.mp3'
      )

      stats = described_class.new(account: account).perform
      expect(stats[:created]).to eq(1)
      expect(OttivCall.find_by(provider_call_id: 'job-1')).to be_present
    end

    it 'não grava em dry_run' do
      build_private_recording_message(content: 'Gravação da chamada (ID: dry-1)')
      stats = described_class.new(account: account, dry_run: true).perform
      expect(stats[:created]).to eq(1)
      expect(OttivCall.find_by(provider_call_id: 'dry-1')).to be_nil
    end

    it 'ignora duplicata' do
      build_private_recording_message(content: 'Gravação da chamada (ID: dup-1)')
      described_class.new(account: account).perform
      stats = described_class.new(account: account).perform
      expect(stats[:skipped_duplicate]).to eq(1)
      expect(stats[:created]).to eq(0)
    end
  end
end
