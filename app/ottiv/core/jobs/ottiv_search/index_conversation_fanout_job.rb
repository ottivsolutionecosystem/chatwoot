# frozen_string_literal: true

module Ottiv
  module Core
    module Jobs
      module OttivSearch
        # Atualiza os campos conversation_* em todos os documentos de mensagens
        # de uma conversa quando status/assignee/priority/labels/last_activity_at mudam.
        #
        # Debounce: usa lock Redis (5s) para evitar 1 fanout por mensagem.
        # Se um fanout já está enfileirado/em execução para a conversa, descarta.
        class IndexConversationFanoutJob < ApplicationJob
          queue_as :ottiv_core_default

          DEBOUNCE_TTL = 5 # segundos
          BATCH_SIZE   = 500

          retry_on ::Ottiv::Meilisearch::Error, wait: :polynomially_longer, attempts: 5
          discard_on ActiveRecord::RecordNotFound

          def perform(conversation_id)
            conversation = Conversation.find(conversation_id)

            return unless account_enabled?(conversation.account_id)
            return unless acquire_lock(conversation_id)

            uid    = Services::OttivIndexNaming.messages_uid(conversation.account_id)
            client = Services::OttivMeilisearchClient.new

            # Partial update em batch dos campos conversation_* para todas as mensagens
            Message.where(conversation_id: conversation_id)
                   .where(message_type: [0, 1])
                   .find_in_batches(batch_size: BATCH_SIZE) do |batch|
              docs = batch.map do |msg|
                Services::OttivMessageDocumentSerializer.conversation_fields(msg, conversation)
              end
              client.update_documents(uid: uid, documents: docs)
            end

            Rails.logger.info(
              "[OttivSearch::FanoutJob] atualizado conversation_#{conversation_id} → #{uid}"
            )
          end

          private

          def account_enabled?(account_id)
            ::Ottiv::Meilisearch.globally_enabled? &&
              Account.find_by(id: account_id)&.ottiv_meilisearch_enabled?
          end

          # Retorna true se conseguiu o lock (job pode prosseguir)
          def acquire_lock(conversation_id)
            key = "ottiv_meili_fanout:#{conversation_id}"
            redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
            # SET NX EX — só seta se não existir (debounce)
            result = redis.set(key, '1', nx: true, ex: DEBOUNCE_TTL)
            result == true || result == 'OK'
          rescue Redis::CannotConnectError, StandardError => e
            Rails.logger.warn("[OttivSearch::FanoutJob] lock Redis falhou (#{e.message}), prosseguindo sem debounce")
            true
          end
        end
      end
    end
  end
end
