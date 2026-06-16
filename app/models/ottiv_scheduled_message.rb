# == Schema Information
#
# Table name: ottiv_scheduled_messages
#
#  id              :bigint           not null, primary key
#  title           :string
#  message_type    :integer          default(0), not null
#  content         :text
#  media_url       :string
#  audio_url       :string
#  quick_reply_id  :bigint
#  account_id      :bigint           not null
#  conversation_id :bigint
#  contact_id      :bigint
#  send_at         :datetime         not null
#  timezone        :string           default("UTC"), not null
#  recurrence      :integer          default(0), not null
#  status          :integer          default(0), not null
#  created_by      :bigint           not null
#  sent_at         :datetime
#  series_id       :string(36)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class OttivScheduledMessage < ApplicationRecord
  belongs_to :account
  belongs_to :conversation, optional: true
  belongs_to :contact, optional: true
  belongs_to :creator, class_name: 'User', foreign_key: :created_by
  has_many :ottiv_scheduled_message_occurrences, foreign_key: :ottiv_scheduled_message_id, dependent: :destroy

  enum message_type: { text: 0, media: 1, audio: 2, quick_reply: 3 }
  enum recurrence: {
    no_recurrence: 0,
    daily: 1,
    weekly: 2,
    biweekly: 3,
    monthly: 4,
    quarterly: 5,
    semiannual: 6,
    annual: 7
  }
  enum status: { scheduled: 0, sent: 1, cancelled: 2, failed: 3 }

  validates :send_at, presence: true
  validates :timezone, presence: true
  validates :account_id, presence: true
  validates :created_by, presence: true
  validates :message_type, presence: true
  validate :send_at_in_future, on: :create
  validate :conversation_required_for_scheduled_message

  before_create :assign_series_id_if_recurrent

  scope :pending,          -> { where(status: :scheduled).where('send_at <= ?', Time.current) }
  scope :by_account,       ->(account_id) { where(account_id: account_id) }
  scope :by_conversation,  ->(conversation_id) { where(conversation_id: conversation_id) }
  scope :by_status,        ->(status) { where(status: Array(status).flat_map { |s| s.to_s.split(',') }) }
  scope :upcoming,         -> { where(status: :scheduled).where('send_at > ?', Time.current).order(send_at: :asc) }
  scope :by_series,        ->(series_id) { where(series_id: series_id) }
  scope :by_send_at_range, ->(from, to) {
    scope = all
    scope = scope.where('send_at >= ?', from) if from.present?
    scope = scope.where('send_at <= ?', to)   if to.present?
    scope
  }

  def mark_as_sent!
    update!(status: :sent, sent_at: Time.current)
  end

  def mark_as_failed!(error_msg = nil)
    update!(status: :failed)
    ottiv_scheduled_message_occurrences.create!(
      status: :failed,
      error_message: error_msg
    ) if error_msg.present?
  end

  def cancel!
    update!(status: :cancelled)
  end

  # Cancels every still-scheduled occurrence in the same series.
  # Falls back to cancelling only this record when series_id is nil
  # (legacy records created before the series_id migration).
  def cancel_series!
    if series_id.present?
      account.ottiv_scheduled_messages
             .where(series_id: series_id, status: :scheduled)
             .update_all(status: OttivScheduledMessage.statuses[:cancelled])
    else
      cancel!
    end
  end

  def has_recurrence?
    !no_recurrence?
  end

  private

  def assign_series_id_if_recurrent
    # Generate a new UUID when creating the first message of a recurrent
    # series. Subsequent occurrences receive the same series_id via
    # CreateService / SendService.
    if has_recurrence? && series_id.blank?
      self.series_id = SecureRandom.uuid
    end
  end

  def send_at_in_future
    return unless send_at

    send_at_utc = if send_at.is_a?(Time) || send_at.is_a?(ActiveSupport::TimeWithZone)
                    send_at.utc
                  elsif send_at.is_a?(String)
                    Time.zone.parse(send_at).utc
                  else
                    send_at.to_time.utc
                  end
    current_time_utc = Time.current.utc

    errors.add(:send_at, 'must be in the future') if send_at_utc <= (current_time_utc - 1.minute)
  end

  def conversation_required_for_scheduled_message
    errors.add(:conversation_id, 'is required for scheduled messages') if conversation_id.blank?
  end
end
