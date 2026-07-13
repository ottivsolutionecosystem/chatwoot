# frozen_string_literal: true

class OttivFinanceNegotiation < ApplicationRecord
  belongs_to :account
  belongs_to :creator, class_name: 'User', foreign_key: :created_by_id
  belongs_to :updater, class_name: 'User', foreign_key: :updated_by_id, optional: true

  has_many :offers, class_name: 'OttivFinanceOffer', foreign_key: :negotiation_id, dependent: :destroy
  has_many :documents, class_name: 'OttivFinanceDocument', foreign_key: :negotiation_id, dependent: :destroy
  has_many :timeline_events, class_name: 'OttivFinanceTimelineEvent', foreign_key: :negotiation_id, dependent: :destroy

  validates :status, presence: true
  validates :priority, presence: true
  validates :customer, presence: true

  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :recent_first, -> { order(updated_at: :desc) }

  def closed?
    %w[closed lost].include?(status)
  end
end
