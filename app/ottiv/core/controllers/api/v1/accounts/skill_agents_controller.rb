module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class SkillAgentsController < ::Api::V1::Accounts::BaseController
            before_action :set_skill_agent, only: [:show, :update, :destroy]
            before_action :check_authorization

            def index
              skill_agents = Current.account.ottiv_skill_agents.includes(:agent, :ottiv_skill)
              skill_agents = skill_agents.where(skill_id: params[:skill_id]) if params[:skill_id].present?
              skill_agents = skill_agents.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params[:active].present?

              render json: skill_agents.order(created_at: :desc).map { |record| serialize_skill_agent(record) }
            end

            def show
              render json: serialize_skill_agent(@skill_agent)
            end

            def create
              skill_agent = Current.account.ottiv_skill_agents.create!(skill_agent_params)
              render json: serialize_skill_agent(skill_agent), status: :created
            rescue ActiveRecord::RecordInvalid => e
              render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end

            def update
              @skill_agent.update!(skill_agent_params)
              render json: serialize_skill_agent(@skill_agent)
            rescue ActiveRecord::RecordInvalid => e
              render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end

            def destroy
              @skill_agent.update!(active: false)
              head :no_content
            end

            private

            def set_skill_agent
              @skill_agent = Current.account.ottiv_skill_agents.includes(:agent, :ottiv_skill).find(params[:id])
            rescue ActiveRecord::RecordNotFound
              render json: { error: 'Skill agent not found' }, status: :not_found
            end

            def check_authorization
              check_admin_authorization?
            end

            def skill_agent_params
              params.require(:ottiv_skill_agent).permit(:skill_id, :agent_id, :active, :last_assigned_at)
            end

            def serialize_skill_agent(record)
              {
                id: record.id,
                account_id: record.account_id,
                skill_id: record.skill_id,
                agent_id: record.agent_id,
                active: record.active,
                last_assigned_at: record.last_assigned_at,
                created_at: record.created_at,
                updated_at: record.updated_at,
                skill: {
                  id: record.ottiv_skill&.id,
                  type: record.ottiv_skill&.type,
                  name: record.ottiv_skill&.name,
                  active: record.ottiv_skill&.active
                },
                agent: {
                  id: record.agent&.id,
                  name: record.agent&.name,
                  email: record.agent&.email,
                  availability_status: record.agent&.availability_status
                }
              }
            end
          end
        end
      end
    end
  end
end
