# frozen_string_literal: true

module Ottiv
  module Analytics
    module Jobs
      class RefreshMetricsJob < ApplicationJob
        queue_as :ottiv_analytics_default

        def perform(account_id)
          Rails.logger.info "Analytics::Jobs::RefreshMetricsJob: Refreshing metrics for account #{account_id}"
        end
      end
    end
  end
end
