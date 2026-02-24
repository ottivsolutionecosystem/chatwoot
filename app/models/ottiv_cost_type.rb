# == Schema Information
#
# Table name: ottiv_cost_types
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  category    :integer          default(0), not null
#  description :text
#  account_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class OttivCostType < ApplicationRecord
  belongs_to :account
  has_many :ottiv_portal_costs, foreign_key: :cost_type_id, dependent: :destroy_async

  enum category: { fixed: 0, variable: 1 }

  validates :name, presence: true, length: { maximum: 255 },
                   uniqueness: { scope: :account_id, message: 'já existe um tipo de custo com este nome nesta conta' }
  validates :category, presence: true
  validates :account_id, presence: true

  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_category, ->(category) { where(category: category) }

  def webhook_data
    {
      id: id,
      name: name,
      category: category,
      description: description,
      account_id: account_id,
      created_at: created_at.to_i,
      updated_at: updated_at.to_i
    }
  end
end

