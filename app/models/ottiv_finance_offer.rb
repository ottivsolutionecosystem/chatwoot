# frozen_string_literal: true

class OttivFinanceOffer < ApplicationRecord
  belongs_to :negotiation, class_name: 'OttivFinanceNegotiation', foreign_key: :negotiation_id

  has_many :installments, class_name: 'OttivFinanceInstallment', foreign_key: :offer_id, dependent: :destroy

  validates :bank_code, :bank_name, :status, presence: true
end
