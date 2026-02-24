# == Schema Information
#
# Table name: ottiv_portals
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  source_id  :string
#  active     :boolean          default(TRUE), not null
#  account_id :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class OttivPortal < ApplicationRecord
  belongs_to :account
  has_many :ottiv_portal_costs, foreign_key: :portal_id, dependent: :destroy_async

  validates :name, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, length: { maximum: 255 },
                   format: { with: /\A[a-z0-9\-_]+\z/, message: 'deve conter apenas letras minúsculas, números, hífens e underscores' },
                   uniqueness: { scope: :account_id, message: 'já existe um portal com este slug nesta conta' }
  validates :account_id, presence: true

  scope :active, -> { where(active: true) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }

  def webhook_data
    {
      id: id,
      name: name,
      slug: slug,
      source_id: source_id,
      active: active,
      account_id: account_id,
      created_at: created_at.to_i,
      updated_at: updated_at.to_i
    }
  end
end

