# frozen_string_literal: true

# Placeholder query for Ottiv Analytics Agents Metrics
# TODO: Implement agents metrics queries
module Ottiv::Analytics
module Queries
  class AgentsMetricsQuery
    def initialize(account:, params: {})
      @account = account
      @params = params
    end

    def perform
      # TODO: Implement agents metrics queries
      []
    end
  end
end
end
