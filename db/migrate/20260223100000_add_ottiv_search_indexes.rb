class AddOttivSearchIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Index 1: Otimiza SearchService#find_conversations_for_contact
    # Cobre: WHERE account_id = ? AND contact_id = ? ... ORDER BY last_activity_at DESC
    # O index atual em (contact_id) não inclui account_id nem last_activity_at
    add_index :conversations,
              [:account_id, :contact_id, :last_activity_at],
              order: { last_activity_at: 'DESC NULLS LAST' },
              algorithm: :concurrently,
              name: 'index_conversations_on_account_contact_activity'

    # Index 2: Otimiza ConversationHelpers#ottiv_preload_last_messages
    # A query usa DISTINCT ON (conversation_id) ORDER BY conversation_id ASC, id DESC
    # com WHERE message_type != :activity
    # O index (conversation_id) existente não suporta o sort composto por (conversation_id, id DESC)
    add_index :messages,
              [:conversation_id, :id],
              order: { id: 'DESC' },
              where: "message_type != 2", # 2 = activity no enum do Message
              algorithm: :concurrently,
              name: 'index_messages_on_conversation_id_desc_non_activity'
  end
end
