class Api::V1::Accounts::OttivCostTypesController < Api::V1::Accounts::BaseController
  before_action :set_cost_type, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    cost_types = Current.account.ottiv_cost_types

    # Filter by category
    cost_types = cost_types.where(category: params[:category]) if params[:category].present?

    cost_types = cost_types.order(created_at: :desc)

    render json: cost_types
  end

  def show
    render json: @cost_type
  end

  def create
    @cost_type = Current.account.ottiv_cost_types.create!(cost_type_params)
    render json: @cost_type, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def update
    @cost_type.update!(cost_type_params)
    render json: @cost_type
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def destroy
    @cost_type.destroy!
    head :no_content
  end

  private

  def set_cost_type
    @cost_type = Current.account.ottiv_cost_types.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Cost type not found' }, status: :not_found
  end

  def check_authorization
    check_admin_authorization?
  end

  def cost_type_params
    params.require(:ottiv_cost_type).permit(:name, :category, :description)
  end
end

