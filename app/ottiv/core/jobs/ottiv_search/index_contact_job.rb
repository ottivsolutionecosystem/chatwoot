# frozen_string_literal: true

module Ottiv
  module Core
    module Jobs
      module OttivSearch
        # Indexa (ou re-indexa) um contato no Meilisearch.
        # Enfileirado após after_commit em Contact (create/update).
        class IndexContactJob < ApplicationJob
          queue_as :ottiv_core_default

          retry_on ::Ottiv::Meilisearch::Error, wait: :polynomially_longer, attempts: 5
          discard_on ActiveRecord::RecordNotFound

          def perform(contact_id)
            contact = Contact.find(contact_id)

            return unless account_enabled?(contact.account_id)

            doc = Services::OttivContactDocumentSerializer.call(contact)
            uid = Services::OttivIndexNaming.contacts_uid(contact.account_id)
            client = Services::OttivMeilisearchClient.new
            client.add_or_update_documents(uid: uid, documents: [doc])

            Rails.logger.info("[OttivSearch::IndexContactJob] indexed contact_#{contact_id} → #{uid}")
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
