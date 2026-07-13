# frozen_string_literal: true

# Legacy Auttus config table (shared database).
class Config < ApplicationRecord
  self.table_name = 'config'
  self.primary_key = 'account_id'

  # A coluna "attributes" colide com ActiveRecord::AttributeMethods#attributes
  # e faz o Rails levantar ActiveRecord::DangerousAttributeError ao instanciar
  # o model. Ignoramos essa coluna aqui (o valor ainda pode ser lido via SQL
  # bruto, como faz Ottiv::Core::Controllers::Api::Ottiv::ConfigsController).
  self.ignored_columns = ['attributes']

  belongs_to :account, foreign_key: :account_id, optional: true
end
