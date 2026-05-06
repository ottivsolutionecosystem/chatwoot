# frozen_string_literal: true

module Ottiv
  module Core
    module Jobs
      module OttivSearch
        # Backfill completo de mensagens e contatos de uma conta no Meilisearch.
        #
        # Paginado e idempotente — re-indexar o mesmo documento apenas sobrescreve.
        # Usa queue ottiv_core_low para não disputar com operações de produção.
        #
        # Parâmetros:
        #   account_id:     ID da conta
        #   batch_size:     Tamanho do batch (padrão 500)
        #   index_messages: Boolean (padrão true)
        #   index_contacts: Boolean (padrão true)
        class BackfillAccountJob < ApplicationJob
          queue_as :ottiv_core_low

          retry_on ::Ottiv::Meilisearch::Error, wait: :exponentially_longer, attempts: 5

          def perform(account_id, batch_size: 500, index_messages: true, index_contacts: true)
            return unless ::Ottiv::Meilisearch.globally_enabled?

            account = Account.find_by(id: account_id)
            return if account.nil?
            return unless account.ottiv_meilisearch_enabled?

            client = Services::OttivMeilisearchClient.new

            # Provisioanr índices antes do backfill
            Services::OttivIndexProvisioner.new(account_id: account_id, client: client).call

            backfill_messages(account_id, batch_size, client) if index_messages
            backfill_contacts(account_id, batch_size, client) if index_contacts

            Rails.logger.info("[OttivSearch::BackfillAccountJob] conta #{account_id} concluída")
          end

          private

          def backfill_messages(account_id, batch_size, client)
            uid = Services::OttivIndexNaming.messages_uid(account_id)
            count = 0

            Message.includes(:conversation)
                   .where(account_id: account_id, message_type: [0, 1])
                   .find_in_batches(batch_size: batch_size) do |batch|
              docs = batch.filter_map { |msg| Services::OttivMessageDocumentSerializer.call(msg) }
              next if docs.empty?

              client.add_or_update_documents(uid: uid, documents: docs)
              count += docs.size
              Rails.logger.debug("[OttivSearch::Backfill] mensagens indexadas: #{count} (conta #{account_id})")
            end

            Rails.logger.info("[OttivSearch::Backfill] #{count} mensagens indexadas para conta #{account_id}")
          end

          def backfill_contacts(account_id, batch_size, client)
            uid = Services::OttivIndexNaming.contacts_uid(account_id)
            count = 0

            Contact.where(account_id: account_id)
                   .find_in_batches(batch_size: batch_size) do |batch|
              docs = batch.map { |c| Services::OttivContactDocumentSerializer.call(c) }
              client.add_or_update_documents(uid: uid, documents: docs)
              count += docs.size
              Rails.logger.debug("[OttivSearch::Backfill] contatos indexados: #{count} (conta #{account_id})")
            end

            Rails.logger.info("[OttivSearch::Backfill] #{count} contatos indexados para conta #{account_id}")
          end
        end
      end
    end
  end
end
