module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class SkillsController < ::Api::V1::Accounts::BaseController
            before_action :set_skill, only: [:show, :update, :destroy]
            before_action :check_authorization

            def index
              skills = Current.account.ottiv_skills
              skills = skills.where(type: params[:type].to_s.strip.downcase) if params[:type].present?
              skills = skills.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params[:active].present?
              render json: skills.order(created_at: :desc)
            end

            def show
              render json: @skill
            end

            def create
              skill = Current.account.ottiv_skills.create!(skill_params)
              render json: skill, status: :created
            rescue ActiveRecord::RecordInvalid => e
              render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end

            def update
              @skill.update!(skill_params)
              render json: @skill
            rescue ActiveRecord::RecordInvalid => e
              render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end

            def destroy
              @skill.update!(active: false)
              @skill.ottiv_skill_agents.update_all(active: false, updated_at: Time.current)
              head :no_content
            end

            private

            def set_skill
              @skill = Current.account.ottiv_skills.find(params[:id])
            rescue ActiveRecord::RecordNotFound
              render json: { error: 'Skill not found' }, status: :not_found
            end

            def check_authorization
              check_admin_authorization?
            end

            def skill_params
              params.require(:ottiv_skill).permit(:type, :name, :active)
            end
          end
        end
      end
    end
  end
end
