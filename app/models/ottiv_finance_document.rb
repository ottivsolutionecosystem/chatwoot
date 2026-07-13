# frozen_string_literal: true

class OttivFinanceDocument < ApplicationRecord
  belongs_to :negotiation, class_name: 'OttivFinanceNegotiation', foreign_key: :negotiation_id

  has_one_attached :file

  validates :doc_type, :label, :status, presence: true
end
