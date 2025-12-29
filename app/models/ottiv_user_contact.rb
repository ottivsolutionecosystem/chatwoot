# == Schema Information
#
# Table name: ottiv_user_contacts
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  contact_id :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_ottiv_user_contacts_on_contact_id  (contact_id)
#  index_ottiv_user_contacts_on_user_id     (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (user_id => users.id)
#

class OttivUserContact < ApplicationRecord
  belongs_to :user
  belongs_to :contact

  validates :user_id, presence: true, uniqueness: true
  validates :contact_id, presence: true
end

