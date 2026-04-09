# frozen_string_literal: true

# == Schema Information
#
# Table name: ottiv_calls
#
#  id                        :bigint           not null, primary key
#  account_id                :bigint           not null
#  provider                  :string           not null
#  provider_call_id          :string           not null
#  conversation_id           :bigint
#  user_id                   :bigint           # assignee da conversa (agente atribuído), não o autor da mensagem
#  direction                 :string
#  status                    :string           default("open"), not null
#  started_at                :datetime
#  ended_at                  :datetime
#  duration_seconds          :integer
#  metadata                  :jsonb            not null
#  recording_message_id      :bigint
#  recording_attachment_id   :bigint
#  recording_job_enqueued_at :datetime
#  recording_failure_reason  :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
class OttivCall < ApplicationRecord
  STATUSES = %w[
    open
    pending_recording
    recording_attached
    recording_failed
  ].freeze

  belongs_to :account
  belongs_to :conversation, optional: true
  belongs_to :user, optional: true
  belongs_to :recording_message, class_name: 'Message', optional: true
  belongs_to :recording_attachment, class_name: 'Attachment', optional: true

  validates :provider, presence: true
  validates :provider_call_id, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :pending_recording_stale, lambda { |before_time|
    where(status: 'pending_recording', recording_message_id: nil)
      .where('ottiv_calls.updated_at < ?', before_time)
  }
end
