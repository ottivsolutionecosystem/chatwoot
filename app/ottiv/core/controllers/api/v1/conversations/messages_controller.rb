module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Conversations
          class MessagesController < ::Api::V1::Accounts::Conversations::BaseController
            before_action :set_message, only: [:show]

            def show
              render 'api/v1/accounts/conversations/ottiv_messages/show'
            end

            private

            def set_message
              @message = @conversation.messages.find(params[:message_id])
            rescue ActiveRecord::RecordNotFound
              render json: { error: 'Message not found' }, status: :not_found
            end
          end
        end
      end
    end
  end
end
