# frozen_string_literal: true

# Placeholder service for Ottiv Analytics Agents Metrics
# TODO: Implement agents metrics calculation
module Ottiv::Analytics
module Services
  class AgentsMetricsService
    def initialize(account:, params: {})
      @account = account
      @params = params
    end

    def perform
      # TODO: Implement agents metrics calculation
      { message: 'Agents metrics service not yet implemented' }
    end
  end
end
end

end
