# frozen_string_literal: true

module Ottiv
  module Core
    module Services
      # Cria e configura os índices Meilisearch de uma conta.
      #
      # Idempotente: pode ser chamado N vezes sem efeitos colaterais.
      # Usado pelo ProvisionIndexesJob e pelo endpoint /provision do controller.
      class OttivIndexProvisioner
        include OttivIndexNaming

        MESSAGES_SETTINGS = {
          searchableAttributes: ['content'],
          filterableAttributes: %w[
            inbox_id contact_id conversation_id
            conversation_status conversation_assignee_id
            conversation_priority conversation_labels
            conversation_last_activity_at
            private message_type created_at
          ],
          sortableAttributes: %w[created_at conversation_last_activity_at],
          typoTolerance: {
            enabled: true,
            minWordSizeForTypos: { oneTypo: 4, twoTypos: 7 }
          }
        }.freeze

        CONTACTS_SETTINGS = {
          searchableAttributes: %w[name email phone_digits phone_number],
          filterableAttributes: %w[last_activity_at has_resolved_conversation],
          sortableAttributes: ['last_activity_at'],
          typoTolerance: {
            enabled: true,
            minWordSizeForTypos: { oneTypo: 4, twoTypos: 7 }
          }
        }.freeze

        def initialize(account_id:, client: nil)
          @account_id = account_id
          @client     = client || OttivMeilisearchClient.new
        end

        # Garante que ambos os índices existem e têm settings corretos.
        # Retorna { messages: task_uid, contacts: task_uid }
        def call
          {
            messages: provision_index(
              uid: OttivIndexNaming.messages_uid(@account_id),
              settings: MESSAGES_SETTINGS
            ),
            contacts: provision_index(
              uid: OttivIndexNaming.contacts_uid(@account_id),
              settings: CONTACTS_SETTINGS
            )
          }
        end

        private

        def provision_index(uid:, settings:)
          @client.ensure_index(uid: uid, primary_key: 'id')
          task = @client.update_settings(uid: uid, settings: settings)
          Rails.logger.info("[OttivProvisioner] índice #{uid} provisionado (task #{task['taskUid']})")
          task['taskUid']
        rescue ::Ottiv::Meilisearch::Error => e
          Rails.logger.error("[OttivProvisioner] erro ao provisionar #{uid}: #{e.message}")
          raise
        end
      end
    end
  end
end
