class AddPerformanceIndexesToConversations < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Index 1: Otimiza queries "mine" (minhas conversas)
    # Cobre: WHERE account_id = ? AND assignee_id = ? ORDER BY last_activity_at DESC
    add_index :conversations,
              [:account_id, :assignee_id, :last_activity_at],
              order: { last_activity_at: 'DESC NULLS LAST' },
              algorithm: :concurrently,
              name: 'index_conversations_on_account_assignee_activity'

    # Index 2: Otimiza queries com filtro de status + ordenação
    # Cobre: WHERE account_id = ? AND status = ? ORDER BY last_activity_at DESC
    add_index :conversations,
              [:account_id, :status, :last_activity_at],
              order: { last_activity_at: 'DESC NULLS LAST' },
              algorithm: :concurrently,
              name: 'index_conversations_on_account_status_activity'

    # Index 3: Índice parcial para conversas não atribuídas (unassigned)
    # Cobre: WHERE account_id = ? AND assignee_id IS NULL ORDER BY last_activity_at DESC
    # Índice parcial é menor e mais eficiente para este caso específico
    add_index :conversations,
              [:account_id, :last_activity_at],
              order: { last_activity_at: 'DESC NULLS LAST' },
              where: 'assignee_id IS NULL',
              algorithm: :concurrently,
              name: 'index_conversations_unassigned_by_activity'

    # Index 4: Otimiza queries com filtro por inbox_ids + ordenação
    # Cobre: WHERE account_id = ? AND inbox_id IN (?) ORDER BY last_activity_at DESC
    add_index :conversations,
              [:account_id, :inbox_id, :last_activity_at],
              order: { last_activity_at: 'DESC NULLS LAST' },
              algorithm: :concurrently,
              name: 'index_conversations_on_account_inbox_activity'
  end
end

