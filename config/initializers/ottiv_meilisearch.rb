# frozen_string_literal: true

# Configuração central do Meilisearch para os recursos Ottiv.
#
# Kill switch global: OTTIV_MEILISEARCH_ENABLED=true (env)
# Flag por conta: custom_attributes['ottiv_meilisearch_enabled'] = true
# Ambos precisam estar ativos para a busca usar o Meilisearch.
#
# Nunca levanta erro no boot — se as variáveis estiverem ausentes, a flag
# globally_enabled? retorna false e o sistema usa Postgres normalmente.

module Ottiv
  module Meilisearch
    class Error < StandardError; end
    class TimeoutError < Error; end
    class IndexError < Error; end

    class << self
      def host
        ENV.fetch('MEILISEARCH_HOST', '').presence
      end

      def api_key
        ENV['MEILISEARCH_KEY'].presence
      end

      def globally_enabled?
        ENV['OTTIV_MEILISEARCH_ENABLED'] == 'true' && host.present?
      end

      # Retorna headers HTTP padrão para requests ao Meilisearch
      def default_headers
        headers = { 'Content-Type' => 'application/json' }
        headers['Authorization'] = "Bearer #{api_key}" if api_key.present?
        headers
      end

      # Timeout em segundos para requests ao Meilisearch (leitura e conexão)
      def request_timeout
        (ENV['MEILISEARCH_TIMEOUT'] || '5').to_i
      end
    end
  end
end

# Monkey-patches para enfileirar jobs de indexação após commits nos modelos upstream.
# Executados apenas depois que o app está inicializado (evita autoload preemptivo).
Rails.application.config.after_initialize do
  # ── Account — feature flag ────────────────────────────────────────────────
  Account.include ::Ottiv::Core::Concerns::OttivAccountMeilisearch

  # ── Message ──────────────────────────────────────────────────────────────
  Message.class_eval do
    include ::Ottiv::Core::Concerns::OttivMeilisearchIndexable

    private

    MEILI_WATCHED_COLUMNS = %w[content message_type private].freeze

    def ottiv_meili_index!
      return unless saved_changes.keys.intersect?(MEILI_WATCHED_COLUMNS + ['id'])

      ::Ottiv::Core::Jobs::OttivSearch::IndexMessageJob.perform_later(id)
    end

    def ottiv_meili_remove!
      uid = ::Ottiv::Core::Services::OttivIndexNaming.messages_uid(account_id)
      ::Ottiv::Core::Jobs::OttivSearch::RemoveDocumentJob.perform_later(uid: uid, doc_id: "msg_#{id}")
    end
  end

  # ── Contact ──────────────────────────────────────────────────────────────
  Contact.class_eval do
    include ::Ottiv::Core::Concerns::OttivMeilisearchIndexable

    private

    MEILI_CONTACT_COLUMNS = %w[name email phone_number identifier avatar_url last_activity_at].freeze

    def ottiv_meili_index!
      return unless saved_changes.keys.intersect?(MEILI_CONTACT_COLUMNS + ['id'])

      ::Ottiv::Core::Jobs::OttivSearch::IndexContactJob.perform_later(id)
    end

    def ottiv_meili_remove!
      uid = ::Ottiv::Core::Services::OttivIndexNaming.contacts_uid(account_id)
      ::Ottiv::Core::Jobs::OttivSearch::RemoveDocumentJob.perform_later(uid: uid, doc_id: "contact_#{id}")
    end
  end

  # ── Conversation ─────────────────────────────────────────────────────────
  Conversation.class_eval do
    include ::Ottiv::Core::Concerns::OttivMeilisearchIndexable

    # Campos que disparam fanout nas mensagens da conversa
    MEILI_CONV_COLUMNS = %w[status assignee_id priority label_list last_activity_at].freeze

    private

    def ottiv_meili_index!
      changed = saved_changes.keys
      return unless changed.intersect?(MEILI_CONV_COLUMNS)

      ::Ottiv::Core::Jobs::OttivSearch::IndexConversationFanoutJob.perform_later(id)
    end

    def ottiv_meili_remove!
      msg_uid = ::Ottiv::Core::Services::OttivIndexNaming.messages_uid(account_id)
      ::Ottiv::Core::Jobs::OttivSearch::RemoveDocumentJob.perform_later(
        uid: msg_uid, filter: "conversation_id = #{id}"
      )
    end
  end
end
