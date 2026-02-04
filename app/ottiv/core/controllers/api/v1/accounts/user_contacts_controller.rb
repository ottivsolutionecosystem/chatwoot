module Core
  module Controllers
    module Api
      module V1
        module Accounts
          class UserContactsController < ::Api::V1::Accounts::BaseController
            before_action :set_user
            before_action :load_user_contact, only: [:show, :update, :destroy]
            before_action :validate_contact_belongs_to_account, only: [:create, :update]

            def show
              if @user_contact
                render json: { user_contact: @user_contact.as_json(include: :contact) }
              else
                render json: { user_contact: nil }, status: :ok
              end
            end

            def create
              if @user.ottiv_user_contact.present?
                render json: { error: 'User already has a linked contact' }, status: :unprocessable_entity
                return
              end

              @user_contact = @user.build_ottiv_user_contact(user_contact_params)

              if @user_contact.save
                render json: { user_contact: @user_contact.as_json(include: :contact) }, status: :created
              else
                render json: { errors: @user_contact.errors.full_messages }, status: :unprocessable_entity
              end
            end

            def update
              if @user_contact.nil?
                render json: { error: 'User contact not found' }, status: :not_found
                return
              end

              if @user_contact.update(user_contact_params)
                render json: { user_contact: @user_contact.as_json(include: :contact) }
              else
                render json: { errors: @user_contact.errors.full_messages }, status: :unprocessable_entity
              end
            end

            def destroy
              if @user_contact.nil?
                render json: { error: 'User contact not found' }, status: :not_found
                return
              end

              @user_contact.destroy!
              head :no_content
            end

            def index
              # Buscar todos os ottiv_user_contacts dos usuários da conta atual
              @user_contacts = OttivUserContact
                .joins(:user)
                .where(users: { account_id: Current.account.id })
                .includes(:user, :contact)

              render json: {
                user_contacts: @user_contacts.map do |uc|
                  {
                    user_id: uc.user_id,
                    contact_id: uc.contact_id,
                    created_at: uc.created_at,
                    updated_at: uc.updated_at
                  }
                end
              }
            end

            private

            def set_user
              @user = Current.user
            end

            def load_user_contact
              @user_contact = @user.ottiv_user_contact
            end

            def validate_contact_belongs_to_account
              contact_id = user_contact_params[:contact_id]
              return unless contact_id

              contact = Current.account.contacts.find_by(id: contact_id)
              unless contact
                render json: { error: 'Contact not found in current account' }, status: :not_found
                return
              end
            end

            def user_contact_params
              params.require(:ottiv_user_contact).permit(:contact_id)
            end
          end
        end
      end
    end
  end
end

