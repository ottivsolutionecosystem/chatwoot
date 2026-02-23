# frozen_string_literal: true

# Placeholder controller for Ottiv Analytics Agents
# TODO: Implement agents analytics functionality
module Ottiv::Analytics
module Controllers
  module Api
    module V1
      class AgentsController < ::Api::V1::Accounts::BaseController
        def index
          # TODO: Implement agents metrics
          render json: { message: 'Agents analytics not yet implemented' }
        end
      end
    end
  end
end
end
