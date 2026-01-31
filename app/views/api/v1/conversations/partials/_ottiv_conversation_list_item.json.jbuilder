# Partial otimizado para listagem de conversas
# Retorna apenas os campos necessários para renderizar ConversationItem no frontend
# Evita N+1 queries usando dados pré-carregados via includes

# Meta do contato (sender) e assignee
json.meta do
  json.sender do
    json.id conversation.contact.id
    json.name conversation.contact.name
    json.email conversation.contact.email
    json.phone_number conversation.contact.phone_number
    json.thumbnail conversation.contact.avatar_url
  end
  json.channel conversation.inbox.try(:channel_type)
  
  if conversation.assignee.present?
    json.assignee do
      json.id conversation.assignee.id
      json.account_id conversation.account_id
      json.name conversation.assignee.name
      json.available_name conversation.assignee.available_name
      json.email conversation.assignee.email
      json.role conversation.assignee.role
      json.thumbnail conversation.assignee.avatar_url
    end
  end
  
  if conversation.team.present?
    json.team do
      json.id conversation.team.id
      json.name conversation.team.name
    end
  end
end

# Dados principais da conversa
json.id conversation.display_id
json.account_id conversation.account_id
json.uuid conversation.uuid
json.inbox_id conversation.inbox_id
json.status conversation.status
json.priority conversation.priority
json.labels conversation.cached_label_list_array

# Timestamps
json.created_at conversation.created_at.to_i
json.timestamp conversation.last_activity_at.to_i
json.last_activity_at conversation.last_activity_at.to_i

# ✅ Usar contador pré-carregado (evita N+1)
# O método ottiv_unread_count usa o valor calculado via subquery ou faz fallback automático
json.unread_count conversation.ottiv_unread_count

# ✅ Usar última mensagem pré-carregada (evita N+1)
# O last_non_activity_message é pré-carregado pelo finder otimizado
if conversation.respond_to?(:ottiv_last_message) && conversation.ottiv_last_message.present?
  json.last_non_activity_message do
    msg = conversation.ottiv_last_message
    json.id msg.id
    json.content msg.content
    json.message_type msg.message_type_before_type_cast
    json.private msg.private
    json.created_at msg.created_at.to_i
    if msg.attachments.present?
      json.attachments msg.attachments.map { |att| { file_type: att.file_type, data_url: att.file_url } }
    end
  end
elsif conversation.messages.loaded?
  # Fallback: se messages já foi carregado via includes, usar sem query extra
  last_msg = conversation.messages.select { |m| m.message_type != 'activity' }.max_by(&:id)
  if last_msg.present?
    json.last_non_activity_message do
      json.id last_msg.id
      json.content last_msg.content
      json.message_type last_msg.message_type_before_type_cast
      json.private last_msg.private
      json.created_at last_msg.created_at.to_i
      if last_msg.attachments.present?
        json.attachments last_msg.attachments.map { |att| { file_type: att.file_type, data_url: att.file_url } }
      end
    end
  end
else
  # Fallback final: buscar última mensagem (causa query, mas é fallback)
  last_msg = conversation.messages.non_activity_messages.first
  if last_msg.present?
    json.last_non_activity_message do
      json.id last_msg.id
      json.content last_msg.content
      json.message_type last_msg.message_type_before_type_cast
      json.private last_msg.private
      json.created_at last_msg.created_at.to_i
      if last_msg.attachments.present?
        json.attachments last_msg.attachments.map { |att| { file_type: att.file_type, data_url: att.file_url } }
      end
    end
  end
end

# NÃO incluir:
# - messages[] (array completo) - carregado sob demanda quando usuário abre conversa
# - additional_attributes - raramente usado na lista
# - custom_attributes - não usado na lista
# - can_reply - só necessário quando abre conversa
# - sla_policy_id - não mostrado na lista
# - agent_last_seen_at, contact_last_seen_at - não usados na lista

