module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class SourcesController < ::Api::V1::Accounts::BaseController
            def index
              render json: Source.order(:name).as_json(only: [:id, :name])
            end
          end
        end
      end
    end
  end
end
