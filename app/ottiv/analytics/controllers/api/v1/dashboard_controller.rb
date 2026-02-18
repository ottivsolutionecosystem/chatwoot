# frozen_string_literal: true

# Placeholder controller for Ottiv Analytics Dashboard
# TODO: Implement analytics dashboard functionality
module Ottiv::Analytics
module Controllers
  module Api
    module V1
      class DashboardController < ::Api::V1::Accounts::BaseController
        def index
          # TODO: Implement dashboard metrics
          render json: { message: 'Analytics dashboard not yet implemented' }
        end
      end
    end
  end
end
end

end
