json.data do
  # Meta com todos os contadores
  json.meta do
    json.mine_count @meta_counts[:mine_count]
    json.unassigned_count @meta_counts[:unassigned_count]
    json.assigned_count @meta_counts[:assigned_count]
    json.all_count @all_count
    json.mention_count @mention_count
  end

  # Payload com conversas organizadas por aba
  # ✅ Usando partial otimizado que não faz N+1 queries
  json.payload do
    json.mine do
      json.array! @mine_conversations do |conversation|
        json.partial! 'api/v1/conversations/partials/ottiv_conversation_list_item', formats: [:json], conversation: conversation
      end
    end

    json.mention do
      json.array! @mention_conversations do |conversation|
        json.partial! 'api/v1/conversations/partials/ottiv_conversation_list_item', formats: [:json], conversation: conversation
      end
    end

    if @is_administrator && @all_conversations.any?
      json.all do
        json.array! @all_conversations do |conversation|
          json.partial! 'api/v1/conversations/partials/ottiv_conversation_list_item', formats: [:json], conversation: conversation
        end
      end
    end
  end
end

