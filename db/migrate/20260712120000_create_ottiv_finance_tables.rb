# frozen_string_literal: true

class CreateOttivFinanceTables < ActiveRecord::Migration[7.0]
  def change
    create_table :ottiv_finance_negotiations do |t|
      t.bigint :account_id, null: false
      t.bigint :conversation_id
      t.bigint :contact_id
      t.bigint :deal_id
      t.boolean :finance_conversation_linked, null: false, default: false
      t.string :status, null: false, default: 'draft'
      t.string :priority, null: false, default: 'medium'
      t.jsonb :customer, null: false, default: {}
      t.jsonb :vehicle, default: {}
      t.jsonb :conditions, null: false, default: {}
      t.jsonb :ai_insight, default: {}
      t.string :closure_outcome
      t.string :closure_reason
      t.text :closure_notes
      t.datetime :submitted_at
      t.datetime :closed_at
      t.bigint :created_by_id, null: false
      t.bigint :updated_by_id
      t.timestamps
    end

    add_index :ottiv_finance_negotiations, :account_id, name: 'idx_fin_neg_account'
    add_index :ottiv_finance_negotiations, [:account_id, :status], name: 'idx_fin_neg_acct_status'
    add_index :ottiv_finance_negotiations, [:account_id, :conversation_id], name: 'idx_fin_neg_acct_conv'
    add_index :ottiv_finance_negotiations, [:account_id, :contact_id], name: 'idx_fin_neg_acct_contact'
    add_index :ottiv_finance_negotiations, [:account_id, :submitted_at], name: 'idx_fin_neg_acct_submitted'
    add_index :ottiv_finance_negotiations, [:account_id, :created_by_id], name: 'idx_fin_neg_acct_creator'
    add_foreign_key :ottiv_finance_negotiations, :accounts, column: :account_id

    create_table :ottiv_finance_offers do |t|
      t.bigint :negotiation_id, null: false
      t.string :bank_code, null: false
      t.string :bank_name, null: false
      t.string :status, null: false, default: 'in_analysis'
      t.string :opinion_outcome
      t.integer :retorno
      t.decimal :required_down_payment, precision: 12, scale: 2
      t.decimal :approved_financed_amount, precision: 12, scale: 2
      t.decimal :financing_percent, precision: 5, scale: 2
      t.text :fi_notes
      t.text :rejection_reason
      t.jsonb :pending_items, default: []
      t.jsonb :requested_docs, default: []
      t.datetime :queried_at
      t.datetime :responded_at
      t.jsonb :raw_response, default: {}
      t.timestamps
    end

    add_index :ottiv_finance_offers, :negotiation_id
    add_foreign_key :ottiv_finance_offers, :ottiv_finance_negotiations, column: :negotiation_id

    create_table :ottiv_finance_installments do |t|
      t.bigint :offer_id, null: false
      t.integer :installments, null: false
      t.decimal :installment_value, precision: 12, scale: 2, null: false
      t.decimal :rate, precision: 8, scale: 4
      t.decimal :cet, precision: 8, scale: 4
      t.jsonb :marks, default: []
      t.timestamps
    end

    add_index :ottiv_finance_installments, :offer_id
    add_foreign_key :ottiv_finance_installments, :ottiv_finance_offers, column: :offer_id

    create_table :ottiv_finance_documents do |t|
      t.bigint :negotiation_id, null: false
      t.string :doc_type, null: false
      t.string :label, null: false
      t.string :kind, null: false, default: 'file'
      t.string :status, null: false, default: 'pending'
      t.text :value
      t.text :notes
      t.string :file_name
      t.bigint :requested_by_id
      t.datetime :requested_at
      t.datetime :received_at
      t.timestamps
    end

    add_index :ottiv_finance_documents, :negotiation_id
    add_foreign_key :ottiv_finance_documents, :ottiv_finance_negotiations, column: :negotiation_id

    create_table :ottiv_finance_timeline_events do |t|
      t.bigint :negotiation_id, null: false
      t.string :event_type, null: false
      t.string :title, null: false
      t.text :description
      t.jsonb :metadata, default: {}
      t.bigint :created_by_id
      t.datetime :created_at, null: false
    end

    add_index :ottiv_finance_timeline_events, :negotiation_id
    add_foreign_key :ottiv_finance_timeline_events, :ottiv_finance_negotiations, column: :negotiation_id
  end
end
