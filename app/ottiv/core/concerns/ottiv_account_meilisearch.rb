# frozen_string_literal: true

module Ottiv
  module Core
    module Concerns
      # Adiciona o método ottiv_meilisearch_enabled? ao modelo Account.
      # Lê de custom_attributes['ottiv_meilisearch_enabled'].
      #
      # O kill switch global (OTTIV_MEILISEARCH_ENABLED env) ainda precisa
      # estar true para a flag por conta ter efeito.
      module OttivAccountMeilisearch
        extend ActiveSupport::Concern

        def ottiv_meilisearch_enabled?
          custom_attributes&.fetch('ottiv_meilisearch_enabled', false) == true ||
            custom_attributes&.fetch('ottiv_meilisearch_enabled', 'false') == 'true'
        end

        def ottiv_meilisearch_enable!
          update!(custom_attributes: (custom_attributes || {}).merge('ottiv_meilisearch_enabled' => true))
        end

        def ottiv_meilisearch_disable!
          update!(custom_attributes: (custom_attributes || {}).merge('ottiv_meilisearch_enabled' => false))
        end
      end
    end
  end
end
