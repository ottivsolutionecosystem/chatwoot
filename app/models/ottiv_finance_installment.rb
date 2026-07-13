# frozen_string_literal: true

class OttivFinanceInstallment < ApplicationRecord
  belongs_to :offer, class_name: 'OttivFinanceOffer', foreign_key: :offer_id

  validates :installments, :installment_value, presence: true
end
