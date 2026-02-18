# frozen_string_literal: true

# Placeholder query for Ottiv Analytics Inbox Metrics
# TODO: Implement inbox metrics queries
module Ottiv::Analytics
module Queries
  class InboxMetricsQuery
    def initialize(account:, params: {})
      @account = account
      @params = params
    end

    def perform
      # TODO: Implement inbox metrics queries
      []
    end
  end
end
end

end
