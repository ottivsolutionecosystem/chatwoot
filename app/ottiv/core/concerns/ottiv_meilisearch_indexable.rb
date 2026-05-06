# frozen_string_literal: true

module Ottiv
  module Core
    module Concerns
      # Mixin que adiciona after_commit hooks para indexação/remoção no Meilisearch.
      #
      # Incluído via monkey-patch nos modelos Message, Contact e Conversation
      # a partir do initializer ottiv_meilisearch.rb — sem modificar código upstream.
      #
      # Todos os hooks são no-op quando a flag global ou por conta está desligada.
      module OttivMeilisearchIndexable
        extend ActiveSupport::Concern

        included do
          # Subclasses precisam implementar `ottiv_meili_account_id`
          after_commit :ottiv_meili_index!,   on: %i[create update], if: :ottiv_meili_enabled?
          after_commit :ottiv_meili_remove!,  on: :destroy,          if: :ottiv_meili_globally_enabled?
        end

        private

        def ottiv_meili_globally_enabled?
          ::Ottiv::Meilisearch.globally_enabled?
        end

        def ottiv_meili_enabled?
          return false unless ottiv_meili_globally_enabled?

          account = Account.find_by(id: ottiv_meili_account_id)
          account&.ottiv_meilisearch_enabled? || false
        end

        def ottiv_meili_account_id
          respond_to?(:account_id) ? account_id : nil
        end

        def ottiv_meili_index!
          # Cada modelo sobrescreve este método
        end

        def ottiv_meili_remove!
          # Cada modelo sobrescreve este método
        end
      end
    end
  end
end
