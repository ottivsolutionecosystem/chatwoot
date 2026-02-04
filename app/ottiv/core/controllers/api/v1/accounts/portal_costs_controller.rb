module Ottiv
  module Core
    module Controllers
      module Api
        module V1
          module Accounts
            class PortalCostsController < ::Api::V1::Accounts::BaseController
              before_action :set_portal_cost, only: [:show, :update, :destroy]
              before_action :check_authorization

              def index
                portal_costs = OttivPortalCost.joins(:ottiv_portal)
                                             .where(ottiv_portals: { account_id: Current.account.id })
                                             .includes(:ottiv_portal, :ottiv_cost_type)

                # Filter by portal_id
                portal_costs = portal_costs.where(portal_id: params[:portal_id]) if params[:portal_id].present?

                # Filter by cost_type_id
                portal_costs = portal_costs.where(cost_type_id: params[:cost_type_id]) if params[:cost_type_id].present?

                # Filter by period
                if params[:start_date].present? && params[:end_date].present?
                  begin
                    start_date = Date.parse(params[:start_date])
                    end_date = Date.parse(params[:end_date])
                    portal_costs = portal_costs.by_period(start_date, end_date)
                  rescue ArgumentError
                    render json: { error: 'Invalid date format. Use YYYY-MM-DD' }, status: :unprocessable_entity
                    return
                  end
                end

                portal_costs = portal_costs.order(reference_period_start: :desc)

                render json: portal_costs.as_json(
                  include: {
                    ottiv_portal: {
                      only: [:id, :name, :slug]
                    },
                    ottiv_cost_type: {
                      only: [:id, :name, :category]
                    }
                  }
                )
              end

              def show
                render json: @portal_cost.as_json(
                  include: {
                    ottiv_portal: {
                      only: [:id, :name, :slug]
                    },
                    ottiv_cost_type: {
                      only: [:id, :name, :category]
                    }
                  }
                )
              end

              def create
                # Verificar se o portal pertence à conta
                portal = Current.account.ottiv_portals.find(portal_cost_params[:portal_id])
                
                # Verificar se o cost_type pertence à conta
                cost_type = Current.account.ottiv_cost_types.find(portal_cost_params[:cost_type_id])

                @portal_cost = OttivPortalCost.create!(
                  portal_cost_params.merge(portal_id: portal.id)
                )
                render json: @portal_cost.as_json(
                  include: {
                    ottiv_portal: {
                      only: [:id, :name, :slug]
                    },
                    ottiv_cost_type: {
                      only: [:id, :name, :category]
                    }
                  }
                ), status: :created
              rescue ActiveRecord::RecordNotFound => e
                render json: { error: 'Portal or cost type not found' }, status: :not_found
              rescue ActiveRecord::RecordInvalid => e
                render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
              end

              def update
                # Validar que portal_id e cost_type_id pertencem à conta se forem atualizados
                if portal_cost_params[:portal_id].present?
                  Current.account.ottiv_portals.find(portal_cost_params[:portal_id])
                end
                
                if portal_cost_params[:cost_type_id].present?
                  Current.account.ottiv_cost_types.find(portal_cost_params[:cost_type_id])
                end

                @portal_cost.update!(portal_cost_params)
                render json: @portal_cost.as_json(
                  include: {
                    ottiv_portal: {
                      only: [:id, :name, :slug]
                    },
                    ottiv_cost_type: {
                      only: [:id, :name, :category]
                    }
                  }
                )
              rescue ActiveRecord::RecordNotFound => e
                render json: { error: 'Portal or cost type not found' }, status: :not_found
              rescue ActiveRecord::RecordInvalid => e
                render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
              end

              def destroy
                @portal_cost.destroy!
                head :no_content
              end

              private

              def set_portal_cost
                @portal_cost = OttivPortalCost.joins(:ottiv_portal)
                                            .where(ottiv_portals: { account_id: Current.account.id })
                                            .find(params[:id])
              rescue ActiveRecord::RecordNotFound
                render json: { error: 'Portal cost not found' }, status: :not_found
              end

              def check_authorization
                check_admin_authorization?
              end

              def portal_cost_params
                params.require(:ottiv_portal_cost).permit(:portal_id, :cost_type_id, :amount, :reference_period_start, :reference_period_end, :description)
              end
            end
          end
        end
      end
    end
  end

  end
