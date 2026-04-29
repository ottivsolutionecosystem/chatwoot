class EnableUnaccentAndOttivSearchTrigramIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  # Habilita unaccent (remoção de acentos para ILIKE/trigrama),
  # cria wrapper IMMUTABLE necessário para indexar e adiciona
  # índices GIN trigrama nas colunas usadas por Ottiv::Core::Services::SearchService.
  def up
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    enable_extension 'unaccent' unless extension_enabled?('unaccent')

    # Wrapper IMMUTABLE em torno de unaccent (a função unaccent original é STABLE,
    # o que impede o uso direto em índices). O dicionário 'unaccent' é o padrão.
    execute <<~SQL.squish
      CREATE OR REPLACE FUNCTION immutable_unaccent(text) RETURNS text AS
      $$ SELECT unaccent('unaccent', $1) $$
      LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT
    SQL

    # Índice trigrama em contacts.name normalizado (case + acento insensível).
    unless index_name_exists?(:contacts, 'index_contacts_on_name_trgm_unaccent')
      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_contacts_on_name_trgm_unaccent
          ON contacts USING gin (immutable_unaccent(coalesce(name, '')) gin_trgm_ops)
      SQL
    end

    # Índice trigrama em contacts.phone_number reduzido a dígitos puros.
    # Permite buscar números com qualquer máscara: "(44) 99999-0000", "44999990000" etc.
    unless index_name_exists?(:contacts, 'index_contacts_on_phone_digits_trgm')
      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_contacts_on_phone_digits_trgm
          ON contacts USING gin (regexp_replace(coalesce(phone_number, ''), '\\D', '', 'g') gin_trgm_ops)
      SQL
    end

    # Índice trigrama em messages.content normalizado, restrito a mensagens
    # incoming/outgoing (message_type 0 e 1) — atividades não são pesquisadas.
    unless index_name_exists?(:messages, 'index_messages_on_content_trgm_unaccent')
      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_messages_on_content_trgm_unaccent
          ON messages USING gin (immutable_unaccent(coalesce(content, '')) gin_trgm_ops)
          WHERE message_type IN (0, 1)
      SQL
    end
  end

  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_on_content_trgm_unaccent'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_contacts_on_phone_digits_trgm'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_contacts_on_name_trgm_unaccent'
    execute 'DROP FUNCTION IF EXISTS immutable_unaccent(text)'
    # Não removemos as extensões: outras partes do schema podem depender delas.
  end
end
