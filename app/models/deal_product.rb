class DealProduct < ApplicationRecord
  self.table_name = 'deal_products'

  belongs_to :deal
  belongs_to :product, optional: true

  validates :deal_id, presence: true
  validates :price, presence: true
end
