# frozen_string_literal: true

module Ottiv::Core::Services::Finance
  module BankOptions
    ALL = [
      { code: 'BV', name: 'BV Financeira' },
      { code: 'ITAU', name: 'Itaú' },
      { code: 'SANTANDER', name: 'Santander' },
      { code: 'BRADESCO', name: 'Bradesco' },
      { code: 'PAN', name: 'Banco Pan' },
      { code: 'SAFRA', name: 'Safra' },
      { code: 'CREDITAS', name: 'Creditas' },
      { code: 'OMNI', name: 'Omni' },
      { code: 'CARBANK', name: 'Carbank' },
      { code: 'CREDICARRO', name: 'Credicarro' },
      { code: 'DAYCOVAL', name: 'Daycoval' },
      { code: 'PAULISTA', name: 'Paulista' }
    ].freeze
  end
end
