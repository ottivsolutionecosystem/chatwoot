# frozen_string_literal: true

module Ottiv
  module Core
    module Jobs
      module OttivSearch
        # Cria e configura os índices Meilisearch de uma conta.
        # Idempotente — pode ser re-executado sem efeitos colaterais.
        class ProvisionIndexesJob < ApplicationJob
          queue_as :ottiv_core_default

          retry_on ::Ottiv::Meilisearch::Error, wait: :exponentially_longer, attempts: 5

          def perform(account_id)
            return unless ::Ottiv::Meilisearch.globally_enabled?

            Services::OttivIndexProvisioner.new(account_id: account_id).call
            Rails.logger.info("[OttivSearch::ProvisionIndexesJob] conta #{account_id} provisionada")
          end
        end
      end
    end
  end
end
