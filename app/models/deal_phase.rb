class DealPhase < ApplicationRecord
  self.table_name = 'deal_phase'

  belongs_to :deal, optional: true
  belongs_to :contact, optional: true

  validates :deal_id, presence: true
end
