module Core
  module Controllers
    module Api
      module V1
        module Accounts
          class PortalsController < ::Api::V1::Accounts::BaseController
            before_action :set_portal, only: [:show, :update, :destroy]
            before_action :check_authorization

            def index
              portals = Current.account.ottiv_portals

              # Filter by active status
              portals = portals.where(active: params[:active]) if params[:active].present?

              # Filter by slug
              portals = portals.where(slug: params[:slug]) if params[:slug].present?

              portals = portals.order(created_at: :desc)

              render json: portals
            end

            def show
              render json: @portal
            end

            def create
              @portal = Current.account.ottiv_portals.create!(portal_params)
              render json: @portal, status: :created
            rescue ActiveRecord::RecordInvalid => e
              render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end

            def update
              @portal.update!(portal_params)
              render json: @portal
            rescue ActiveRecord::RecordInvalid => e
              render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end

            def destroy
              @portal.destroy!
              head :no_content
            end

            private

            def set_portal
              @portal = Current.account.ottiv_portals.find(params[:id])
            rescue ActiveRecord::RecordNotFound
              render json: { error: 'Portal not found' }, status: :not_found
            end

            def check_authorization
              check_admin_authorization?
            end

            def portal_params
              params.require(:ottiv_portal).permit(:name, :slug, :source_id, :active)
            end
          end
        end
      end
    end
  end
end

