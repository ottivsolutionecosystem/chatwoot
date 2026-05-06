# Modelo Deal para mapear a tabela deals existente no banco de dados
# As tabelas pipelines e pipeline_stages existem no DB mas seus modelos
# não estão definidos no Chatwoot (são gerenciados pela API Auttus).
class Deal < ApplicationRecord
  self.table_name = 'deals'

  # Soft delete
  default_scope { where(delete_at: nil) }

  # Associações disponíveis no Chatwoot
  belongs_to :account
  belongs_to :contact, optional: true
  belongs_to :user, foreign_key: 'assignee_id', optional: true

  has_many :deal_phases,
           -> { order(created_at: :desc) },
           foreign_key: 'deal_id',
           dependent: :destroy
  has_many :deal_products, foreign_key: 'deal_id', dependent: :destroy
  has_many :deal_registrations, foreign_key: 'deal_id', dependent: :destroy

  # Validações mínimas (deals podem ser criados pela API Auttus)
  validates :account_id, presence: true

  # Scopes
  scope :active, -> { where(delete_at: nil) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_contact, ->(contact_id) { where(contact_id: contact_id) }
  scope :by_pipeline, ->(pipeline_id) { where(pipeline_id: pipeline_id) }

  # Métodos auxiliares
  def active?
    delete_at.nil?
  end

  def deleted?
    delete_at.present?
  end

  def assignee_name
    user&.name
  end

  # Busca o estágio do pipeline diretamente no banco (sem modelo Rails)
  def pipeline_stage_data
    return nil unless stage_id

    @pipeline_stage_data ||= ActiveRecord::Base.connection.exec_query(
      'SELECT id, name, color, position, probability FROM pipeline_stages WHERE id = $1 LIMIT 1',
      'SQL',
      [stage_id]
    ).first
  end

  # Busca o pipeline diretamente no banco (sem modelo Rails)
  def pipeline_data
    return nil unless pipeline_id

    @pipeline_data ||= ActiveRecord::Base.connection.exec_query(
      'SELECT id, name, description FROM pipelines WHERE id = $1 LIMIT 1',
      'SQL',
      [pipeline_id]
    ).first
  end
end
