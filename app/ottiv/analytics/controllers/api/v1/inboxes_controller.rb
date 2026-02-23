# frozen_string_literal: true

# Placeholder controller for Ottiv Analytics Inboxes
# TODO: Implement inboxes analytics functionality
module Ottiv::Analytics
module Controllers
  module Api
    module V1
      class InboxesController < ::Api::V1::Accounts::BaseController
        def index
          # TODO: Implement inboxes metrics
          render json: { message: 'Inboxes analytics not yet implemented' }
        end
      end
    end
  end
end
end
