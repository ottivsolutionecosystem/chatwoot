class OttivSkillAgent < ApplicationRecord
  belongs_to :account
  belongs_to :ottiv_skill, foreign_key: :skill_id
  belongs_to :agent, class_name: 'User'

  validates :account_id, presence: true
  validates :skill_id, presence: true
  validates :agent_id, presence: true
  validates :agent_id, uniqueness: { scope: [:account_id, :skill_id], message: 'ja vinculado a esta skill' }
  validate :skill_belongs_to_account
  validate :agent_belongs_to_account

  scope :active, -> { where(active: true) }
  scope :for_skill, ->(skill_id) { where(skill_id: skill_id) }
  scope :lru_order, -> { order(Arel.sql('last_assigned_at NULLS FIRST, id ASC')) }

  private

  def skill_belongs_to_account
    return if ottiv_skill.blank? || account_id.blank?
    return if ottiv_skill.account_id == account_id

    errors.add(:skill_id, 'nao pertence a esta conta')
  end

  def agent_belongs_to_account
    return if agent_id.blank? || account_id.blank?
    return if AccountUser.exists?(account_id: account_id, user_id: agent_id)

    errors.add(:agent_id, 'nao pertence a esta conta')
  end
end
