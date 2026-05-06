# frozen_string_literal: true

module Ottiv
  module Core
    module Jobs
      module OttivSearch
        # Remove um documento de um índice Meilisearch.
        # Enfileirado após after_commit (destroy) em Message, Contact ou Conversation.
        #
        # Para Message/Contact: doc_id = "msg_{id}" ou "contact_{id}"
        # Para Conversation (destroy): remove todos os documentos via filtro
        class RemoveDocumentJob < ApplicationJob
          queue_as :ottiv_core_default

          retry_on ::Ottiv::Meilisearch::Error, wait: :polynomially_longer, attempts: 3

          # Parâmetros:
          #   uid:     UID do índice (ex.: "ottiv_messages_acc_1")
          #   doc_id:  ID do documento (ex.: "msg_123")
          #   filter:  String de filtro para remoção em massa (opcional)
          def perform(uid:, doc_id: nil, filter: nil)
            return unless ::Ottiv::Meilisearch.globally_enabled?

            client = Services::OttivMeilisearchClient.new

            if filter.present?
              client.delete_documents_by_filter(uid: uid, filter: filter)
              Rails.logger.info("[OttivSearch::RemoveDocumentJob] removidos por filtro '#{filter}' → #{uid}")
            elsif doc_id.present?
              client.delete_document(uid: uid, doc_id: doc_id)
              Rails.logger.info("[OttivSearch::RemoveDocumentJob] removido #{doc_id} → #{uid}")
            end
          end
        end
      end
    end
  end
end
