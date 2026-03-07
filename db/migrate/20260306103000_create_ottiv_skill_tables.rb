class CreateOttivSkillTables < ActiveRecord::Migration[7.0]
  def change
    create_table :ottiv_skills do |t|
      t.bigint :account_id, null: false
      t.string :type, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :ottiv_skills, :account_id, name: 'index_ottiv_skills_on_account_id'
    add_index :ottiv_skills, [:account_id, :type, :name], unique: true, name: 'idx_ottiv_skills_account_type_name'
    add_foreign_key :ottiv_skills, :accounts, column: :account_id

    create_table :ottiv_skill_agents do |t|
      t.bigint :account_id, null: false
      t.bigint :skill_id, null: false
      t.bigint :agent_id, null: false
      t.datetime :last_assigned_at
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :ottiv_skill_agents, :account_id, name: 'index_ottiv_skill_agents_on_account_id'
    add_index :ottiv_skill_agents, :skill_id, name: 'index_ottiv_skill_agents_on_skill_id'
    add_index :ottiv_skill_agents, :agent_id, name: 'index_ottiv_skill_agents_on_agent_id'
    add_index :ottiv_skill_agents, [:account_id, :skill_id, :agent_id], unique: true, name: 'idx_ottiv_skill_agents_account_skill_agent'
    add_index :ottiv_skill_agents,
              [:account_id, :skill_id, :active, :last_assigned_at],
              name: 'idx_ottiv_skill_agents_lru_lookup'

    add_foreign_key :ottiv_skill_agents, :accounts, column: :account_id
    add_foreign_key :ottiv_skill_agents, :ottiv_skills, column: :skill_id
    add_foreign_key :ottiv_skill_agents, :users, column: :agent_id
  end
end
