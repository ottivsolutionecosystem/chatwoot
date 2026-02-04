# Usar o mesmo partial usado na listagem para manter consistência
json.partial! 'api/v1/conversations/partials/ottiv_conversation_list_item', 
  formats: [:json], 
  conversation: @conversation

