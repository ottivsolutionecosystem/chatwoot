# frozen_string_literal: true

# Garantir que os namespaces Ottiv sejam carregados antes dos models
# Isso resolve problemas de autoloading com Zeitwerk

# Carregar namespaces raiz
require Rails.root.join('app/ottiv')
require Rails.root.join('app/ottiv/core')
require Rails.root.join('app/ottiv/core/concerns')

# Forçar carregamento dos concerns
require Rails.root.join('app/ottiv/core/concerns/conversation_helpers')
require Rails.root.join('app/ottiv/core/concerns/redis_keys')

# Log para debug
if defined?(Rails.logger) && Rails.logger
  Rails.logger.info "Ottiv namespaces carregados com sucesso"
end
