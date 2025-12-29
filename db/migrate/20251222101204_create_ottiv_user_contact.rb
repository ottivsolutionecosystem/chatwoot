class CreateOttivUserContact < ActiveRecord::Migration[7.0]
  def change
    create_table :ottiv_user_contacts do |t|
      t.bigint :user_id, null: false
      t.bigint :contact_id, null: false
      t.timestamps
    end

    add_index :ottiv_user_contacts, :user_id, unique: true, name: 'index_ottiv_user_contacts_on_user_id'
    add_index :ottiv_user_contacts, :contact_id, name: 'index_ottiv_user_contacts_on_contact_id'
    add_foreign_key :ottiv_user_contacts, :users, column: :user_id
    add_foreign_key :ottiv_user_contacts, :contacts, column: :contact_id
  end
end

