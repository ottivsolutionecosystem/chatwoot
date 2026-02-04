# frozen_string_literal: true

# Placeholder job for Ottiv Analytics Refresh Metrics
# TODO: Implement metrics refresh functionality
module Analytics
  module Jobs
    class RefreshMetricsJob < ApplicationJob
      queue_as :ottiv_analytics_default

      def perform(account_id)
        # TODO: Implement metrics refresh
        Rails.logger.info "Analytics::Jobs::RefreshMetricsJob: Refreshing metrics for account #{account_id}"
      end
    end
  end
end

  end
