class OttivPersonalCannedResponse < ApplicationRecord
  belongs_to :account
  belongs_to :user

  validates :short_code, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true
  validates :short_code, uniqueness: {
    scope: [:account_id, :user_id],
    message: 'já existe uma mensagem pronta com este atalho'
  }

  scope :search, lambda { |term|
    where('short_code ILIKE :q OR content ILIKE :q', q: "%#{term}%")
  }

  scope :order_by_search, lambda { |term|
    short_code_starts_with = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 1', "#{term}%"])
    short_code_like = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 0.5', "%#{term}%"])
    content_like = sanitize_sql_array(['WHEN content ILIKE ? THEN 0.2', "%#{term}%"])
    order_clause = "CASE #{short_code_starts_with} #{short_code_like} #{content_like} ELSE 0 END"
    order(Arel.sql(order_clause) => :desc)
  }
end
