json.access_token resource.access_token.token
# account_id: Current.account (header x-account) > active_account_user (fallback)
json.account_id Current.account&.id || resource.active_account_user&.account_id
json.available_name resource.available_name
json.avatar_url resource.avatar_url
json.confirmed resource.confirmed?
json.display_name resource.display_name
json.message_signature resource.message_signature
json.email resource.email
json.hmac_identifier resource.hmac_identifier if GlobalConfig.get('CHATWOOT_INBOX_HMAC_KEY')['CHATWOOT_INBOX_HMAC_KEY'].present?
json.id resource.id
json.inviter_id resource.active_account_user&.inviter_id
json.name resource.name
json.provider resource.provider
json.pubsub_token resource.pubsub_token

# Retornar todos os custom_attributes do usuário (sem filtrar por account)
# O frontend filtra os wavoip_tokens pela account_id da sessão
custom_attrs = resource.custom_attributes || {}

# Converter wavoip_tokens do formato antigo (hash) para o novo formato (array) se necessário
if custom_attrs['wavoip_tokens'].present?
  if custom_attrs['wavoip_tokens'].is_a?(Hash)
    # Formato antigo: hash indexado por account_id - converter para array
    custom_attrs['wavoip_tokens'] = custom_attrs['wavoip_tokens'].flat_map do |acc_id, tokens|
      tokens.map { |t| t.merge('account_id' => acc_id.to_i) }
    end
  end
  # Se já é array, manter como está (já tem account_id em cada token)
end

# Sempre retornar todos os custom_attributes (incluindo todos os wavoip_tokens de todas as accounts)
json.custom_attributes custom_attrs

json.role resource.active_account_user&.role
json.ui_settings resource.ui_settings
json.uid resource.uid
json.type resource.type
json.accounts do
  json.array! resource.account_users do |account_user|
    json.id account_user.account_id
    json.name account_user.account.name
    json.status account_user.account.status
    json.active_at account_user.active_at
    json.role account_user.role
    json.permissions account_user.permissions
    # the actual availability user has configured
    json.availability account_user.availability
    # availability derived from presence
    json.availability_status account_user.availability_status
    json.auto_offline account_user.auto_offline
    json.partial! 'api/v1/models/account_user', account_user: account_user if ChatwootApp.enterprise?
  end
end
