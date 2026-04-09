# frozen_string_literal: true

# Com S3/MinIO, o padrão do Active Storage é redirect (302) para o object store.
# Clientes que só alcançam o host do Chatwoot (sem rota ao MinIO) precisam do proxy:
# GET /rails/active_storage/blobs/proxy/... faz o Rails ler o arquivo e devolver o corpo.
unless ActiveModel::Type::Boolean.new.cast(ENV.fetch('ACTIVE_STORAGE_DIRECT_SERVICE_URL', 'false'))
  service = ENV.fetch('ACTIVE_STORAGE_SERVICE', 'local').to_s
  if %w[s3_compatible amazon].include?(service)
    Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
  end
end
