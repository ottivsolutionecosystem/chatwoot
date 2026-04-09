# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ottiv::Core::Jobs::FetchCallRecordingJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    create(:inbox_member, user: user, inbox: conversation.inbox)
    conversation.update!(assignee: user)
  end

  def fake_mp3_io
    tf = Tempfile.new(['wavoip', '.mp3'])
    tf.binmode
    tf.write("ID3\x03\x00fake mp3 payload #{SecureRandom.hex(8)}")
    tf.rewind
    tf.define_singleton_method(:content_type) { 'audio/mpeg' }
    tf.define_singleton_method(:original_filename) { 'rec.mp3' }
    tf
  end

  it 'is queued on ottiv_core_low' do
    call = OttivCall.create!(
      account: account,
      provider: 'wavoip',
      provider_call_id: 'q1',
      conversation: conversation,
      user: user,
      status: 'pending_recording'
    )
    expect { described_class.perform_later(call.id) }
      .to have_enqueued_job(described_class).on_queue('ottiv_core_low')
  end

  it 'creates private message and attachment and updates ottiv_call' do
    call = OttivCall.create!(
      account: account,
      provider: 'wavoip',
      provider_call_id: 'dl1',
      conversation: conversation,
      user: user,
      status: 'pending_recording'
    )

    expect(Down).to receive(:download).and_return(fake_mp3_io)

    described_class.perform_now(call.id)

    call.reload
    expect(call.status).to eq('recording_attached')
    expect(call.user_id).to eq(conversation.assignee_id)
    expect(call.recording_message_id).to be_present
    msg = Message.find(call.recording_message_id)
    expect(msg.private).to be(true)
    expect(msg.attachments.audio.count).to eq(1)
  end

  it 'is idempotent when recording_message_id is already set' do
    call = OttivCall.create!(
      account: account,
      provider: 'wavoip',
      provider_call_id: 'id1',
      conversation: conversation,
      user: user,
      status: 'recording_attached',
      recording_message_id: create(:message, conversation: conversation, account: account, message_type: :outgoing, sender: user).id
    )

    expect(Down).not_to receive(:download)
    described_class.perform_now(call.id)
  end

  it 'marks failed when conversation is missing' do
    call = OttivCall.create!(
      account: account,
      provider: 'wavoip',
      provider_call_id: 'nc1',
      conversation: nil,
      user: user,
      status: 'pending_recording'
    )

    expect(Down).not_to receive(:download)
    described_class.perform_now(call.id)
    expect(call.reload.status).to eq('recording_failed')
  end

  it 'marks failed on unexpected JSON from Wavoip' do
    call = OttivCall.create!(
      account: account,
      provider: 'wavoip',
      provider_call_id: 'js1',
      conversation: conversation,
      user: user,
      status: 'pending_recording'
    )

    tf = Tempfile.new(['j', '.json'])
    tf.write({ status: 'ERROR', message: 'x' }.to_json)
    tf.rewind
    tf.define_singleton_method(:content_type) { 'application/json' }
    allow(Down).to receive(:download).and_return(tf)

    described_class.perform_now(call.id)
    expect(call.reload.status).to eq('recording_failed')
  end
end
