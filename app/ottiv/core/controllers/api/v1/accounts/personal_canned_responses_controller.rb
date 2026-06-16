module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class PersonalCannedResponsesController < ::Api::V1::Accounts::BaseController
            before_action :set_personal_canned_response, only: [:update, :destroy]

            def create
              @record = Current.account.ottiv_personal_canned_responses.new(
                personal_canned_response_params.merge(user_id: Current.user.id)
              )
              @record.save!
              render json: serialize(@record), status: :created
            rescue ActiveRecord::RecordInvalid => e
              render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end

            def update
              @record.update!(personal_canned_response_params)
              render json: serialize(@record)
            rescue ActiveRecord::RecordInvalid => e
              render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end

            def destroy
              @record.destroy!
              head :no_content
            end

            private

            def set_personal_canned_response
              @record = Current.account.ottiv_personal_canned_responses
                                       .find_by!(id: params[:id], user_id: Current.user.id)
            rescue ActiveRecord::RecordNotFound
              render json: { error: 'Mensagem pronta não encontrada' }, status: :not_found
            end

            def personal_canned_response_params
              params.require(:ottiv_personal_canned_response).permit(:short_code, :content)
            end

            def serialize(record)
              {
                id: record.id,
                short_code: record.short_code,
                content: record.content,
                personal: true,
                created_at: record.created_at,
                updated_at: record.updated_at
              }
            end
          end
        end
      end
    end
  end
end
