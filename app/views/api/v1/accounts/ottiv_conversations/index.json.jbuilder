json.data do
  json.meta do
    json.mine_count @conversations_count[:mine_count]
    json.assigned_count @conversations_count[:assigned_count]
    json.unassigned_count @conversations_count[:unassigned_count]
    json.all_count @conversations_count[:all_count]
    json.count_filter @count_filter # Total de registros filtrados (antes da paginação)
  end
  # ✅ Usando partial otimizado que evita N+1 queries
  json.payload do
    json.array! @conversations do |conversation|
      json.partial! 'api/v1/conversations/partials/ottiv_conversation_list_item', formats: [:json], conversation: conversation
    end
  end
end



