# frozen_string_literal: true

module Ottiv::Core::Services::Finance
  module BankAdapters
    class Base
      def query(_negotiation, bank_codes: nil)
        raise NotImplementedError
      end
    end

    class StubAdapter < Base
      def query(_negotiation, bank_codes: nil)
        banks = if bank_codes.present?
                  bank_codes.map do |code|
                    BankOptions::ALL.find { |b| b[:code] == code } || { code: code, name: code }
                  end
                else
                  BankOptions::ALL.first(4)
                end

        banks.map do |bank|
          {
            bank_code: bank[:code],
            bank_name: bank[:name],
            status: 'in_analysis',
            installment_options: [],
            queried_at: Time.current
          }
        end
      end
    end
  end
end
