# frozen_string_literal: true

class CreateOttivCalls < ActiveRecord::Migration[7.0]
  def change
    create_table :ottiv_calls do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :provider, null: false
      t.string :provider_call_id, null: false
      t.bigint :conversation_id
      t.bigint :user_id
      t.string :direction
      t.string :status, null: false, default: 'open'
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :duration_seconds
      t.jsonb :metadata, null: false, default: {}
      t.bigint :recording_message_id
      t.bigint :recording_attachment_id
      t.datetime :recording_job_enqueued_at
      t.text :recording_failure_reason

      t.timestamps
    end

    add_index :ottiv_calls, [:account_id, :provider, :provider_call_id], unique: true, name: 'index_ottiv_calls_on_account_provider_call'
    add_index :ottiv_calls, [:account_id, :status]
    add_index :ottiv_calls, :conversation_id
    add_index :ottiv_calls, :user_id
    add_index :ottiv_calls, :recording_message_id

    add_foreign_key :ottiv_calls, :conversations, column: :conversation_id, validate: false
    add_foreign_key :ottiv_calls, :users, column: :user_id, validate: false
    add_foreign_key :ottiv_calls, :messages, column: :recording_message_id, validate: false
    add_foreign_key :ottiv_calls, :attachments, column: :recording_attachment_id, validate: false
  end
end
