# frozen_string_literal: true

# Placeholder service for Ottiv Analytics Inbox Metrics
# TODO: Implement inbox metrics calculation
module Analytics
module Services
  class InboxMetricsService
    def initialize(account:, params: {})
      @account = account
      @params = params
    end

    def perform
      # TODO: Implement inbox metrics calculation
      { message: 'Inbox metrics service not yet implemented' }
    end
  end
end
end

end
