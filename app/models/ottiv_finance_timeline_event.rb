# frozen_string_literal: true

class OttivFinanceTimelineEvent < ApplicationRecord
  self.record_timestamps = false

  belongs_to :negotiation, class_name: 'OttivFinanceNegotiation', foreign_key: :negotiation_id
  belongs_to :creator, class_name: 'User', foreign_key: :created_by_id, optional: true

  validates :event_type, :title, :created_at, presence: true
end
