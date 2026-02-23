# frozen_string_literal: true

# Placeholder controller for Ottiv Analytics Conversations
# TODO: Implement conversations analytics functionality
module Ottiv::Analytics
module Controllers
  module Api
    module V1
      class ConversationsController < ::Api::V1::Accounts::BaseController
        def index
          # TODO: Implement conversations metrics
          render json: { message: 'Conversations analytics not yet implemented' }
        end
      end
    end
  end
end
end
