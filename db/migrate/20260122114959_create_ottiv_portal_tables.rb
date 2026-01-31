class CreateOttivPortalTables < ActiveRecord::Migration[7.0]
  def change
    # Tabela de portais
    create_table :ottiv_portals do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :source_id
      t.boolean :active, null: false, default: true
      t.bigint :account_id, null: false
      t.timestamps
    end

    add_index :ottiv_portals, :account_id, name: 'index_ottiv_portals_on_account_id'
    add_index :ottiv_portals, [:account_id, :slug], unique: true, name: 'index_ottiv_portals_on_account_id_and_slug'
    add_index :ottiv_portals, :active, name: 'index_ottiv_portals_on_active'
    add_foreign_key :ottiv_portals, :accounts, column: :account_id

    # Tabela de tipos de custo
    create_table :ottiv_cost_types do |t|
      t.string :name, null: false
      t.integer :category, null: false, default: 0
      t.text :description
      t.bigint :account_id, null: false
      t.timestamps
    end

    add_index :ottiv_cost_types, :account_id, name: 'index_ottiv_cost_types_on_account_id'
    add_index :ottiv_cost_types, [:account_id, :name], unique: true, name: 'index_ottiv_cost_types_on_account_id_and_name'
    add_index :ottiv_cost_types, :category, name: 'index_ottiv_cost_types_on_category'
    add_foreign_key :ottiv_cost_types, :accounts, column: :account_id

    # Tabela de custos do portal
    create_table :ottiv_portal_costs do |t|
      t.bigint :portal_id, null: false
      t.bigint :cost_type_id, null: false
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.date :reference_period_start, null: false
      t.date :reference_period_end, null: false
      t.text :description
      t.timestamps
    end

    add_index :ottiv_portal_costs, :portal_id, name: 'index_ottiv_portal_costs_on_portal_id'
    add_index :ottiv_portal_costs, :cost_type_id, name: 'index_ottiv_portal_costs_on_cost_type_id'
    add_index :ottiv_portal_costs, :reference_period_start, name: 'index_ottiv_portal_costs_on_reference_period_start'
    add_index :ottiv_portal_costs, :reference_period_end, name: 'index_ottiv_portal_costs_on_reference_period_end'
    add_index :ottiv_portal_costs, [:portal_id, :reference_period_start, :reference_period_end], 
              name: 'index_ottiv_portal_costs_on_portal_and_period'
    add_foreign_key :ottiv_portal_costs, :ottiv_portals, column: :portal_id
    add_foreign_key :ottiv_portal_costs, :ottiv_cost_types, column: :cost_type_id
  end
end

