module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class CannedResponsesController < ::Api::V1::Accounts::BaseController
            def index
              service = ::Ottiv::Core::Services::CannedResponses::ListForAgentService.new(
                account: Current.account,
                user: Current.user,
                search: params[:search],
                personal_only: params[:personal_only] == 'true',
                shared_only: params[:shared_only] == 'true'
              )

              render json: service.perform
            end
          end
        end
      end
    end
  end
end
