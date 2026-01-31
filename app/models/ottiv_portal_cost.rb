# == Schema Information
#
# Table name: ottiv_portal_costs
#
#  id                      :bigint           not null, primary key
#  portal_id               :bigint           not null
#  cost_type_id            :bigint           not null
#  amount                  :decimal(10, 2)   not null
#  reference_period_start   :date             not null
#  reference_period_end     :date             not null
#  description             :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class OttivPortalCost < ApplicationRecord
  belongs_to :ottiv_portal
  belongs_to :ottiv_cost_type

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :reference_period_start, presence: true
  validates :reference_period_end, presence: true
  validate :reference_period_end_after_start

  scope :by_portal, ->(portal_id) { where(portal_id: portal_id) }
  scope :by_cost_type, ->(cost_type_id) { where(cost_type_id: cost_type_id) }
  scope :by_period, ->(start_date, end_date) { where(reference_period_start: start_date..end_date) }

  def webhook_data
    {
      id: id,
      portal_id: portal_id,
      cost_type_id: cost_type_id,
      amount: amount.to_f,
      reference_period_start: reference_period_start.to_s,
      reference_period_end: reference_period_end.to_s,
      description: description,
      created_at: created_at.to_i,
      updated_at: updated_at.to_i
    }
  end

  private

  def reference_period_end_after_start
    return unless reference_period_start && reference_period_end

    errors.add(:reference_period_end, 'deve ser posterior à data de início') if reference_period_end < reference_period_start
  end
end

