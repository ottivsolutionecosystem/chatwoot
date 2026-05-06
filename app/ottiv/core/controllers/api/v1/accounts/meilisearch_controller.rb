# frozen_string_literal: true

module Ottiv
  module Core
    module Controllers
      module Api
        module V1
          module Accounts
            # Endpoints de validação/operação do Meilisearch por conta.
            # Todos exigem autenticação de agente ou superior (BaseController).
            #
            # Constantes de serviço sempre com prefixo ::Ottiv::Core::Services:: —
            # dentro deste controller aninhado, `Services::Foo` ou `OttivIndexNaming`
            # em PascalCase seriam resolvidos como constantes relativas erradas.
            #
            # Rotas disponíveis:
            #   GET  /api/ottiv/v1/accounts/:id/ottiv_meilisearch/health
            #   POST /api/ottiv/v1/accounts/:id/ottiv_meilisearch/provision
            #   POST /api/ottiv/v1/accounts/:id/ottiv_meilisearch/index_sample
            #   POST /api/ottiv/v1/accounts/:id/ottiv_meilisearch/test_search
            #   POST /api/ottiv/v1/accounts/:id/ottiv_meilisearch/reindex_account
            class MeilisearchController < ::Api::V1::Accounts::BaseController
              # ── health ──────────────────────────────────────────────────────

              # GET .../ottiv_meilisearch/health
              # Retorna status do servidor Meilisearch e info dos índices desta conta.
              def health
                client = meilisearch_client
                server_health = client.health

                uids = ::Ottiv::Core::Services::OttivIndexNaming.all_uids(Current.account.id)
                indexes = uids.transform_values do |uid|
                  client.get_index(uid)
                rescue ::Ottiv::Meilisearch::Error
                  { uid: uid, status: 'not_found' }
                end

                render json: {
                  status: server_health['status'],
                  host: ::Ottiv::Meilisearch.host,
                  globally_enabled: ::Ottiv::Meilisearch.globally_enabled?,
                  account_enabled: Current.account.ottiv_meilisearch_enabled?,
                  indexes: indexes
                }
              rescue ::Ottiv::Meilisearch::Error => e
                render json: { status: 'unavailable', error: e.message }, status: :service_unavailable
              end

              # ── provision ───────────────────────────────────────────────────

              # POST .../ottiv_meilisearch/provision
              # Cria/atualiza índices da conta com settings corretos (idempotente).
              def provision
                tasks = ::Ottiv::Core::Services::OttivIndexProvisioner.new(account_id: Current.account.id).call
                render json: { status: 'provisioned', tasks: tasks }
              rescue ::Ottiv::Meilisearch::Error => e
                render json: { error: e.message }, status: :service_unavailable
              end

              # ── index_sample ────────────────────────────────────────────────

              # POST .../ottiv_meilisearch/index_sample
              # Body: { contacts_limit: 50, messages_limit: 100 }
              # Indexa N contatos e M mensagens da conta para teste rápido.
              def index_sample
                contacts_limit = (params[:contacts_limit] || 50).to_i.clamp(1, 500)
                messages_limit = (params[:messages_limit] || 100).to_i.clamp(1, 1000)

                client = meilisearch_client
                account_id = Current.account.id

                # Provisionar se necessário
                ::Ottiv::Core::Services::OttivIndexProvisioner.new(account_id: account_id, client: client).call

                # Indexar amostra de contatos
                contacts = Current.account.contacts.limit(contacts_limit)
                contact_docs = contacts.map { |c| ::Ottiv::Core::Services::OttivContactDocumentSerializer.call(c) }
                client.add_or_update_documents(
                  uid: ::Ottiv::Core::Services::OttivIndexNaming.contacts_uid(account_id),
                  documents: contact_docs
                )

                # Indexar amostra de mensagens
                messages = Current.account.messages
                                  .where(message_type: [0, 1])
                                  .includes(:conversation)
                                  .order(created_at: :desc)
                                  .limit(messages_limit)
                message_docs = messages.filter_map { |m| ::Ottiv::Core::Services::OttivMessageDocumentSerializer.call(m) }
                client.add_or_update_documents(
                  uid: ::Ottiv::Core::Services::OttivIndexNaming.messages_uid(account_id),
                  documents: message_docs
                )

                render json: {
                  status: 'indexed',
                  contacts_indexed: contact_docs.size,
                  messages_indexed: message_docs.size
                }
              rescue ::Ottiv::Meilisearch::Error => e
                render json: { error: e.message }, status: :service_unavailable
              end

              # ── test_search ─────────────────────────────────────────────────

              # POST .../ottiv_meilisearch/test_search
              # Body: { q: "jose", index: "contacts"|"messages", filters: {}, limit: 10 }
              # Retorna hits brutos sem hidratação Postgres — para validação direta.
              def test_search
                q       = params[:q].to_s
                index   = params[:index].to_s.presence || 'contacts'
                limit   = (params[:limit] || 10).to_i.clamp(1, 100)
                filters = build_raw_filters(params[:filters])

                uid = case index
                      when 'messages' then ::Ottiv::Core::Services::OttivIndexNaming.messages_uid(Current.account.id)
                      when 'contacts' then ::Ottiv::Core::Services::OttivIndexNaming.contacts_uid(Current.account.id)
                      else
                        render json: { error: 'index deve ser "contacts" ou "messages"' }, status: :unprocessable_entity
                        return
                      end

                result = meilisearch_client.search(
                  uid: uid, q: q, filter: filters.presence, limit: limit
                )

                render json: {
                  index: uid,
                  q: q,
                  hits: result['hits'],
                  total: result['totalHits'] || result['estimatedTotalHits'],
                  processing_time_ms: result['processingTimeMs']
                }
              rescue ::Ottiv::Meilisearch::Error => e
                render json: { error: e.message }, status: :service_unavailable
              end

              # ── reindex_account ─────────────────────────────────────────────

              # POST .../ottiv_meilisearch/reindex_account
              # Enfileira BackfillAccountJob para reindexação completa assíncrona.
              def reindex_account
                unless ::Ottiv::Meilisearch.globally_enabled?
                  render json: { error: 'OTTIV_MEILISEARCH_ENABLED não está ativo' }, status: :unprocessable_entity
                  return
                end

                ::Ottiv::Core::Jobs::OttivSearch::BackfillAccountJob.perform_later(Current.account.id)
                render json: { status: 'enqueued', account_id: Current.account.id }
              end

              private

              def meilisearch_client
                ::Ottiv::Core::Services::OttivMeilisearchClient.new
              end

              # Converte params[:filters] (Hash) em Array de strings de filtro Meilisearch
              def build_raw_filters(raw)
                return nil if raw.blank?
                return raw if raw.is_a?(Array) || raw.is_a?(String)

                raw.to_h.filter_map do |key, value|
                  next if value.blank?

                  if value.is_a?(Array)
                    "#{key} IN [\"#{value.join('", "')}\"]"
                  else
                    "#{key} = #{value.inspect}"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
