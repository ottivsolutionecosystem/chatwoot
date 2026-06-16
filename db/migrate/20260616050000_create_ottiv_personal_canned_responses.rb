class CreateOttivPersonalCannedResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :ottiv_personal_canned_responses do |t|
      t.bigint :account_id, null: false
      t.bigint :user_id, null: false
      t.string :short_code, null: false
      t.text :content, null: false
      t.timestamps
    end

    add_index :ottiv_personal_canned_responses,
              [:account_id, :user_id, :short_code],
              unique: true,
              name: 'idx_ottiv_personal_canned_responses_account_user_code'

    add_index :ottiv_personal_canned_responses, :account_id,
              name: 'idx_ottiv_personal_canned_responses_account'

    add_foreign_key :ottiv_personal_canned_responses, :accounts, column: :account_id
    add_foreign_key :ottiv_personal_canned_responses, :users, column: :user_id
  end
end
