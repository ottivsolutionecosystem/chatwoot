# frozen_string_literal: true

namespace :ottiv do
  namespace :meilisearch do
    desc 'Backfill Meilisearch para uma conta ou todas as contas com flag ligada. Ex: rake "ottiv:meilisearch:backfill[1]" ou rake "ottiv:meilisearch:backfill[all]"'
    task :backfill, [:account_id] => :environment do |_t, args|
      unless ::Ottiv::Meilisearch.globally_enabled?
        puts '[OttivMeili] OTTIV_MEILISEARCH_ENABLED não está true ou MEILISEARCH_HOST não configurado. Abortando.'
        next
      end

      arg = args[:account_id].to_s.strip

      accounts = if arg == 'all'
                   Account.where("custom_attributes->>'ottiv_meilisearch_enabled' = 'true'")
                 else
                   Account.where(id: arg.to_i)
                 end

      if accounts.empty?
        puts "[OttivMeili] Nenhuma conta encontrada para '#{arg}'"
        next
      end

      accounts.each do |account|
        puts "[OttivMeili] Iniciando backfill da conta #{account.id} (#{account.name})..."
        ::Ottiv::Core::Jobs::OttivSearch::BackfillAccountJob.perform_now(
          account.id,
          batch_size: (ENV['MEILI_BATCH_SIZE'] || 500).to_i
        )
        puts "[OttivMeili] Backfill da conta #{account.id} concluído."
      end
    end

    desc 'Provisiona índices Meilisearch de uma conta. Ex: rake "ottiv:meilisearch:provision[1]"'
    task :provision, [:account_id] => :environment do |_t, args|
      unless ::Ottiv::Meilisearch.globally_enabled?
        puts '[OttivMeili] OTTIV_MEILISEARCH_ENABLED não está true. Abortando.'
        next
      end

      account_id = args[:account_id].to_i
      if account_id.zero?
        puts '[OttivMeili] Informe um account_id válido.'
        next
      end

      puts "[OttivMeili] Provisionando índices para conta #{account_id}..."
      ::Ottiv::Core::Services::OttivIndexProvisioner.new(account_id: account_id).call
      puts "[OttivMeili] Índices provisionados: #{::Ottiv::Core::Services::OttivIndexNaming.all_uids(account_id).values.join(', ')}"
    end

    desc 'Remove índices Meilisearch de uma conta (dev/reset). Ex: rake "ottiv:meilisearch:reset[1]"'
    task :reset, [:account_id] => :environment do |_t, args|
      account_id = args[:account_id].to_i
      if account_id.zero?
        puts '[OttivMeili] Informe um account_id válido.'
        next
      end

      client = ::Ottiv::Core::Services::OttivMeilisearchClient.new
      uids   = ::Ottiv::Core::Services::OttivIndexNaming.all_uids(account_id).values

      uids.each do |uid|
        client.delete("/indexes/#{uid}")
        puts "[OttivMeili] Índice #{uid} removido."
      rescue ::Ottiv::Meilisearch::Error => e
        puts "[OttivMeili] Aviso ao remover #{uid}: #{e.message}"
      end
    end

    desc 'Exibe status do Meilisearch e lista índices da conta. Ex: rake "ottiv:meilisearch:status[1]"'
    task :status, [:account_id] => :environment do |_t, args|
      client = ::Ottiv::Core::Services::OttivMeilisearchClient.new
      health = client.health
      puts "[OttivMeili] Status: #{health['status']}"
      puts "[OttivMeili] Host: #{::Ottiv::Meilisearch.host}"
      puts "[OttivMeili] Global enabled: #{::Ottiv::Meilisearch.globally_enabled?}"

      account_id = args[:account_id].to_s.strip
      if account_id.present? && account_id != '0'
        uids = ::Ottiv::Core::Services::OttivIndexNaming.all_uids(account_id.to_i)
        uids.each do |type, uid|
          begin
            info = client.get_index(uid)
            puts "[OttivMeili] #{type}: #{uid} — #{info['numberOfDocuments'] || 'N/A'} docs"
          rescue ::Ottiv::Meilisearch::Error => e
            puts "[OttivMeili] #{type}: #{uid} — não encontrado (#{e.message})"
          end
        end
      end
    rescue ::Ottiv::Meilisearch::Error => e
      puts "[OttivMeili] Erro ao conectar: #{e.message}"
    end
  end
end
