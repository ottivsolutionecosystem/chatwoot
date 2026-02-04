module Ottiv
  module Core
    module Controllers
      module Api
        module V1
          module Accounts
            class CalendarItemsController < ::Api::V1::Accounts::BaseController
              before_action :set_calendar_item, only: [:show, :update, :destroy, :complete, :cancel]
              before_action :check_authorization, only: [:show, :update, :destroy, :complete, :cancel]

              def index
                @calendar_items = Current.account.ottiv_calendar_items
                                         .includes(:user, :ottiv_reminders, :conversation, :contacts, :participants)

                # NOVO: Se não for administrador, filtrar apenas registros do usuário logado
                unless Current.user.administrator?
                  @calendar_items = @calendar_items.by_user(Current.user.id)
                end

                # Filter by user (manter para compatibilidade, mas só funciona para admins)
                @calendar_items = @calendar_items.by_user(params[:user_id]) if params[:user_id].present? && Current.user.administrator?

                # Filter by item_type
                @calendar_items = @calendar_items.where(item_type: params[:item_type]) if params[:item_type].present?

                # Filter by status
                @calendar_items = @calendar_items.where(status: params[:status]) if params[:status].present?

                # Filter by date range
                if params[:start_date].present? && params[:end_date].present?
                  start_date = Time.zone.parse(params[:start_date])
                  end_date = Time.zone.parse(params[:end_date])
                  @calendar_items = @calendar_items.by_date_range(start_date, end_date)
                end

                # Filter by conversation
                @calendar_items = @calendar_items.by_conversation(params[:conversation_id]) if params[:conversation_id].present?

                @calendar_items = @calendar_items.order(start_at: :asc)
                render json: @calendar_items.map { |item| calendar_item_to_json(item) }
              end

              def show
                render json: calendar_item_to_json(@calendar_item)
              end

              def create
                service = Ottiv::Core::Services::CalendarItems::CreateService.new(
                  params: calendar_item_params,
                  user: Current.user,
                  account: Current.account
                )

                @calendar_item = service.perform
                render json: calendar_item_to_json(@calendar_item), status: :created
              rescue StandardError => e
                render json: { error: e.message }, status: :unprocessable_entity
              end

              def update
                service = Ottiv::Core::Services::CalendarItems::UpdateService.new(
                  calendar_item: @calendar_item,
                  params: calendar_item_params
                )

                @calendar_item = service.perform
                render json: calendar_item_to_json(@calendar_item)
              rescue StandardError => e
                render json: { error: e.message }, status: :unprocessable_entity
              end

              def destroy
                @calendar_item.destroy!
                head :no_content
              end

              def complete
                service = Ottiv::Core::Services::CalendarItems::CompleteService.new(
                  calendar_item: @calendar_item
                )

                @calendar_item = service.perform
                render json: calendar_item_to_json(@calendar_item)
              rescue StandardError => e
                render json: { error: e.message }, status: :unprocessable_entity
              end

              def cancel
                service = Ottiv::Core::Services::CalendarItems::CancelService.new(
                  calendar_item: @calendar_item
                )

                @calendar_item = service.perform
                render json: calendar_item_to_json(@calendar_item)
              rescue StandardError => e
                render json: { error: e.message }, status: :unprocessable_entity
              end

              private

              def set_calendar_item
                @calendar_item = Current.account.ottiv_calendar_items.find(params[:id])
              rescue ActiveRecord::RecordNotFound
                render json: { error: 'Calendar item not found' }, status: :not_found
              end

              def check_authorization
                # User must be the owner or an admin
                unless @calendar_item.user_id == Current.user.id || Current.user.administrator?
                  render json: { error: 'Unauthorized' }, status: :forbidden
                end
              end

              def calendar_item_params
                params.require(:ottiv_calendar_item).permit(
                  :item_type,
                  :title,
                  :description,
                  :start_at,
                  :end_at,
                  :location,
                  :status,
                  :conversation_id,
                  contact_ids: [],
                  participant_ids: [],
                  reminders: [:notify_at, :channel]
                )
              end

              # Converte calendar_item para JSON com timestamps em Unix timestamp (segundos)
              # Similar ao formato usado em conversations e messages
              def calendar_item_to_json(item)
                json = item.as_json(include: [:ottiv_reminders, :contacts, :participants])

                # Converter timestamps principais para Unix timestamp (segundos)
                json['start_at'] = item.start_at.to_i if item.start_at
                json['end_at'] = item.end_at.to_i if item.end_at
                json['created_at'] = item.created_at.to_i
                json['updated_at'] = item.updated_at.to_i

                # Converter conversation_id de id real para display_id (consistência com API Chatwoot)
                if item.conversation_id.present? && item.conversation
                  json['conversation_id'] = item.conversation.display_id
                end

                # Adicionar dados do usuário (agente responsável)
                if item.user
                  json['user'] = {
                    'id' => item.user.id,
                    'name' => item.user.name,
                    'display_name' => item.user.display_name,
                    'email' => item.user.email,
                    'thumbnail' => item.user.avatar_url
                  }
                end

                # Converter timestamps dos reminders
                if json['ottiv_reminders']
                  json['ottiv_reminders'] = json['ottiv_reminders'].map do |reminder|
                    if reminder['notify_at']
                      reminder['notify_at'] = reminder['notify_at'].is_a?(String) ? Time.parse(reminder['notify_at']).to_i : reminder['notify_at'].to_i
                    end
                    if reminder['created_at']
                      reminder['created_at'] = reminder['created_at'].is_a?(String) ? Time.parse(reminder['created_at']).to_i : reminder['created_at'].to_i
                    end
                    if reminder['updated_at']
                      reminder['updated_at'] = reminder['updated_at'].is_a?(String) ? Time.parse(reminder['updated_at']).to_i : reminder['updated_at'].to_i
                    end
                    reminder
                  end
                end

                json
              end
            end
          end
        end
      end
    end
  end

  end
