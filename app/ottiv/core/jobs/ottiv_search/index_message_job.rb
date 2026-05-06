# frozen_string_literal: true

module Ottiv
  module Core
    module Jobs
      module OttivSearch
        # Indexa (ou re-indexa) uma mensagem no Meilisearch.
        # Enfileirado após after_commit em Message (create/update).
        class IndexMessageJob < ApplicationJob
          queue_as :ottiv_core_default

          # Retry com backoff para tolerar indisponibilidade temporária do Meilisearch
          retry_on ::Ottiv::Meilisearch::Error, wait: :polynomially_longer, attempts: 5
          discard_on ActiveRecord::RecordNotFound

          def perform(message_id)
            message = Message.includes(:conversation).find(message_id)

            return unless account_enabled?(message.account_id)

            doc = Services::OttivMessageDocumentSerializer.call(message)
            return if doc.nil?

            uid = Services::OttivIndexNaming.messages_uid(message.account_id)
            client = Services::OttivMeilisearchClient.new
            client.add_or_update_documents(uid: uid, documents: [doc])

            Rails.logger.info("[OttivSearch::IndexMessageJob] indexed msg_#{message_id} → #{uid}")
          end

          private

          def account_enabled?(account_id)
            ::Ottiv::Meilisearch.globally_enabled? &&
              Account.find_by(id: account_id)&.ottiv_meilisearch_enabled?
          end
        end
      end
    end
  end
end
