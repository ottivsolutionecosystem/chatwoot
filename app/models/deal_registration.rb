class DealRegistration < ApplicationRecord
  self.table_name = 'deal_registration'

  belongs_to :deal

  validates :deal_id, presence: true
  validates :action_type, presence: true
end
