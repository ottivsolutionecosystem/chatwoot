# frozen_string_literal: true

module Ottiv::Core::Services::Finance
  class ComputePreAnalysisService
    def self.call(negotiation)
      customer = negotiation.customer || {}
      conditions = negotiation.conditions || {}
      vehicle = negotiation.vehicle || {}

      flags = []
      score = 70

      unless customer['hasCnh']
        flags << 'Cliente sem CNH'
        score -= 10
      end

      income = customer['income'].to_f
      financed = conditions['financedAmount'].to_f
      if income.positive? && financed > income * 12
        flags << 'Comprometimento de renda elevado'
        score -= 15
      end

      if vehicle['price'].blank? && conditions['vehiclePrice'].blank?
        flags << 'Veículo não definido'
        score -= 5
      end

      suggested_banks = customer['hasCnh'] ? %w[BV SANTANDER ITAU] : %w[PAN SAFRA CREDITAS]

      {
        'approvalProbability' => [[10, score].max, 95].min,
        'suggestedBanks' => suggested_banks,
        'riskFlags' => flags,
        'summary' => flags.any? ? "Atenção: #{flags.join('; ')}" : 'Perfil dentro da média para aprovação.'
      }
    end
  end
end
