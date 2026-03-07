class OttivSkill < ApplicationRecord
  self.inheritance_column = :_type_disabled

  belongs_to :account
  has_many :ottiv_skill_agents, foreign_key: :skill_id, dependent: :destroy_async

  validates :account_id, presence: true
  validates :type, presence: true, length: { maximum: 100 }
  validates :name, presence: true, length: { maximum: 255 }
  validates :name, uniqueness: { scope: [:account_id, :type], message: 'ja existe nesta conta para este tipo' }

  scope :active, -> { where(active: true) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_type, ->(skill_type) { where(type: skill_type) }

  before_validation :normalize_fields

  private

  def normalize_fields
    self.type = type.to_s.strip.downcase.presence
    self.name = name.to_s.strip.downcase.presence
  end
end
