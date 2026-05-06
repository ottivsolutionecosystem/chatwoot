# frozen_string_literal: true

require 'net/http'
require 'json'

module Ottiv
  module Core
    module Services
      # HTTP wrapper sobre a API REST do Meilisearch.
      #
      # Não usa a gem meilisearch-ruby para manter a dependência mínima.
      # Todos os métodos lançam ::Ottiv::Meilisearch::Error em caso de falha
      # (HTTP 4xx/5xx ou timeout), permitindo que o caller faça fallback.
      #
      # Uso:
      #   client = OttivMeilisearchClient.new
      #   client.health
      #   client.search(uid: 'ottiv_messages_acc_1', q: 'jose', filters: 'status=open')
      class OttivMeilisearchClient
        TIMEOUT = ::Ottiv::Meilisearch.request_timeout

        def initialize(host: nil, api_key: nil)
          @host    = (host    || ::Ottiv::Meilisearch.host).to_s.chomp('/')
          @api_key = api_key  || ::Ottiv::Meilisearch.api_key
        end

        # ──── health ─────────────────────────────────────────────────────────

        def health
          get('/health')
        end

        # ──── índices ────────────────────────────────────────────────────────

        def list_indexes
          get('/indexes')
        end

        def get_index(uid)
          get("/indexes/#{uid}")
        end

        # Cria índice se não existir (idempotente). primaryKey obrigatório.
        def ensure_index(uid:, primary_key: 'id')
          payload = { uid: uid, primaryKey: primary_key }
          post('/indexes', payload)
        rescue ::Ottiv::Meilisearch::Error => e
          # 409 = índice já existe — comportamento esperado, ignorar
          raise e unless e.message.include?('index_already_exists')
        end

        # Atualiza settings do índice (searchable, filterable, sortable, typo)
        def update_settings(uid:, settings:)
          patch("/indexes/#{uid}/settings", settings)
        end

        # ──── documentos ─────────────────────────────────────────────────────

        # Adiciona ou atualiza documentos em batch.
        # documents: Array<Hash>
        def add_or_update_documents(uid:, documents:)
          post("/indexes/#{uid}/documents", documents)
        end

        # Atualiza campos específicos de documentos existentes (partial update).
        # documents: Array<Hash com id + campos a atualizar>
        def update_documents(uid:, documents:)
          put("/indexes/#{uid}/documents", documents)
        end

        # Remove documento pelo id do documento (campo primaryKey).
        def delete_document(uid:, doc_id:)
          delete("/indexes/#{uid}/documents/#{doc_id}")
        end

        # Remove documentos por filtro (ex.: "conversation_id = 42")
        def delete_documents_by_filter(uid:, filter:)
          post("/indexes/#{uid}/documents/delete", { filter: filter })
        end

        # ──── busca ──────────────────────────────────────────────────────────

        # Executa busca no índice.
        #
        # Options:
        #   q:       String de busca
        #   filter:  String ou Array de filtros Meilisearch
        #   sort:    Array de strings (ex.: ["created_at:desc"])
        #   offset:  Integer
        #   limit:   Integer (padrão 15)
        #   attributes_to_retrieve: Array<String> (padrão todos)
        def search(uid:, q: '', filter: nil, sort: nil, offset: 0, limit: 15,
                   attributes_to_retrieve: nil)
          payload = { q: q, offset: offset, limit: limit }
          payload[:filter] = filter if filter.present?
          payload[:sort]   = sort   if sort.present?
          payload[:attributesToRetrieve] = attributes_to_retrieve if attributes_to_retrieve.present?

          post("/indexes/#{uid}/search", payload)
        end

        # Busca em múltiplos índices simultaneamente (multi-search)
        def multi_search(queries:)
          post('/multi-search', { queries: queries })
        end

        # ──── tarefas (tasks) ─────────────────────────────────────────────────

        def get_task(task_uid)
          get("/tasks/#{task_uid}")
        end

        # ──── privado ─────────────────────────────────────────────────────────
        private

        def get(path)
          request(:get, path)
        end

        def post(path, body = nil)
          request(:post, path, body)
        end

        def put(path, body = nil)
          request(:put, path, body)
        end

        def patch(path, body = nil)
          request(:patch, path, body)
        end

        def delete(path)
          request(:delete, path)
        end

        def request(method, path, body = nil)
          uri  = URI("#{@host}#{path}")
          http = build_http(uri)

          req = build_request(method, uri, body)
          t0  = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          response = http.request(req)

          elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round
          Rails.logger.debug("[OttivMeili] #{method.upcase} #{path} → #{response.code} (#{elapsed_ms}ms)")

          parse_response(response, method, path)
        rescue Net::OpenTimeout, Net::ReadTimeout => e
          raise ::Ottiv::Meilisearch::TimeoutError, "Timeout em #{method.upcase} #{path}: #{e.message}"
        rescue SocketError, Errno::ECONNREFUSED => e
          raise ::Ottiv::Meilisearch::Error, "Conexão recusada (#{@host}): #{e.message}"
        end

        def build_http(uri)
          http              = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl      = uri.scheme == 'https'
          http.open_timeout = TIMEOUT
          http.read_timeout = TIMEOUT
          http
        end

        def build_request(method, uri, body)
          klass = case method
                  when :get    then Net::HTTP::Get
                  when :post   then Net::HTTP::Post
                  when :put    then Net::HTTP::Put
                  when :patch  then Net::HTTP::Patch
                  when :delete then Net::HTTP::Delete
                  else raise ArgumentError, "método HTTP desconhecido: #{method}"
                  end

          req = klass.new(uri.request_uri)
          ::Ottiv::Meilisearch.default_headers.each { |k, v| req[k] = v }
          req.body = body.to_json if body
          req
        end

        def parse_response(response, method, path)
          code = response.code.to_i
          body = begin
            JSON.parse(response.body || '{}')
          rescue JSON::ParserError
            {}
          end

          return body if code < 400

          error_msg = body['message'] || body['error'] || response.body.to_s.truncate(200)
          error_type = body['code'] || "http_#{code}"
          raise ::Ottiv::Meilisearch::Error, "#{error_type}: #{error_msg} [#{method.upcase} #{path}]"
        end
      end
    end
  end
end
