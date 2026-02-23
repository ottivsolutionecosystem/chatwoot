# frozen_string_literal: true

# Placeholder query for Ottiv Analytics Conversations Metrics
# TODO: Implement conversations metrics queries
module Ottiv::Analytics
module Queries
  class ConversationsMetricsQuery
    def initialize(account:, params: {})
      @account = account
      @params = params
    end

    def perform
      # TODO: Implement conversations metrics queries
      []
    end
  end
end
end
