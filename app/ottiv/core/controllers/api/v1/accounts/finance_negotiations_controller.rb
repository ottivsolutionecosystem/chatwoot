# frozen_string_literal: true

module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class FinanceNegotiationsController < ::Api::V1::Accounts::BaseController
            before_action :set_auth
            before_action :authorize_module_access!
            before_action :set_negotiation, except: %i[index create]

            def index
              negotiations = service.list(
                conversation_id: params[:conversation_id],
                contact_id: params[:contact_id],
                status: params[:status]
              )
              render json: ::Ottiv::Core::Services::Finance::NegotiationSerializer.serialize_collection(negotiations)
            end

            def show
              render json: serialize(@negotiation)
            end

            def create
              negotiation = service.create!(create_params)
              render json: serialize(negotiation), status: :created
            rescue ArgumentError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            def update
              negotiation = service.update!(@negotiation, update_params)
              render json: serialize(negotiation)
            rescue ArgumentError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            def submit
              negotiation = service.submit!(@negotiation)
              render json: serialize(negotiation)
            rescue ArgumentError => e
              render json: { error: e.message }, status: :unprocessable_entity
            end

            def query_banks
              negotiation = service.query_banks!(@negotiation, bank_codes: params[:bank_codes])
              render json: serialize(negotiation)
            rescue ::Ottiv::Core::Services::Finance::AuthorizationService::ForbiddenError => e
              render json: { error: e.message }, status: :forbidden
            end

            def add_opinion
              negotiation = service.add_bank_opinion!(@negotiation, opinion_params)
              render json: serialize(negotiation)
            rescue ::Ottiv::Core::Services::Finance::AuthorizationService::ForbiddenError => e
              render json: { error: e.message }, status: :forbidden
            end

            def update_opinion
              negotiation = service.update_bank_opinion!(@negotiation, params[:offer_id], opinion_params)
              render json: serialize(negotiation)
            rescue ArgumentError => e
              render json: { error: e.message }, status: :unprocessable_entity
            rescue ::Ottiv::Core::Services::Finance::AuthorizationService::ForbiddenError => e
              render json: { error: e.message }, status: :forbidden
            end

            def request_documents
              negotiation = service.request_documents!(@negotiation, documents_params)
              render json: serialize(negotiation)
            rescue ::Ottiv::Core::Services::Finance::AuthorizationService::ForbiddenError => e
              render json: { error: e.message }, status: :forbidden
            end

            def upload_document
              negotiation = service.upload_document!(
                @negotiation,
                params[:document_id],
                file: params[:file],
                file_name: params[:file_name]
              )
              render json: serialize(negotiation)
            end

            def provide_document_data
              negotiation = service.provide_document_data!(
                @negotiation,
                params[:document_id],
                value: params[:value]
              )
              render json: serialize(negotiation)
            end

            def mark_installment
              negotiation = service.mark_installment!(
                @negotiation,
                params[:offer_id],
                params[:installment_id],
                mark: params[:mark]
              )
              render json: serialize(negotiation)
            end

            def close
              negotiation = service.close!(@negotiation, close_params)
              render json: serialize(negotiation)
            rescue ArgumentError => e
              render json: { error: e.message }, status: :unprocessable_entity
            rescue ::Ottiv::Core::Services::Finance::AuthorizationService::ForbiddenError => e
              render json: { error: e.message }, status: :forbidden
            end

            def proposal_sent
              negotiation = service.record_proposal_sent!(@negotiation)
              render json: serialize(negotiation)
            end

            private

            def set_auth
              @auth = ::Ottiv::Core::Services::Finance::AuthorizationService.new(
                user: Current.user,
                account: Current.account
              )
            end

            def service
              @service ||= ::Ottiv::Core::Services::Finance::NegotiationService.new(auth: @auth)
            end

            def authorize_module_access!
              @auth.authorize_access!
            rescue ::Ottiv::Core::Services::Finance::AuthorizationService::ForbiddenError => e
              render json: { error: e.message }, status: :forbidden
              false
            end

            def set_negotiation
              @negotiation = @auth.find_negotiation!(params[:id])
            rescue ActiveRecord::RecordNotFound
              render json: { error: 'Negociação não encontrada' }, status: :not_found
              false
            end

            def serialize(negotiation)
              ::Ottiv::Core::Services::Finance::NegotiationSerializer.serialize(negotiation)
            end

            def create_params
              payload = params[:negotiation] || params
              {
                conversation_id: payload[:conversation_id] || payload[:conversationId],
                contact_id: payload[:contact_id] || payload[:contactId],
                deal_id: payload[:deal_id] || payload[:dealId],
                customer: payload[:customer]&.to_unsafe_h || payload[:customer],
                vehicle: payload[:vehicle]&.to_unsafe_h || payload[:vehicle],
                conditions: payload[:conditions]&.to_unsafe_h || payload[:conditions],
                priority: payload[:priority],
                submit: payload[:submit]
              }
            end

            def update_params
              payload = params[:negotiation] || params
              {
                customer: payload[:customer]&.to_unsafe_h || payload[:customer],
                vehicle: payload[:vehicle]&.to_unsafe_h || payload[:vehicle],
                conditions: payload[:conditions]&.to_unsafe_h || payload[:conditions],
                priority: payload[:priority]
              }.compact
            end

            def opinion_params
              payload = params[:opinion] || params
              {
                bank_code: payload[:bank_code] || payload[:bankCode],
                bank_name: payload[:bank_name] || payload[:bankName],
                status: payload[:status],
                opinion_outcome: payload[:opinion_outcome] || payload[:opinionOutcome],
                retorno: payload[:retorno],
                required_down_payment: payload[:required_down_payment] || payload[:requiredDownPayment],
                approved_financed_amount: payload[:approved_financed_amount] || payload[:approvedFinancedAmount],
                financing_percent: payload[:financing_percent] || payload[:financingPercent],
                fi_notes: payload[:fi_notes] || payload[:fiNotes],
                installment_options: payload[:installment_options] || payload[:installmentOptions],
                rejection_reason: payload[:rejection_reason] || payload[:rejectionReason],
                pending_items: payload[:pending_items] || payload[:pendingItems],
                requested_docs: payload[:requested_docs] || payload[:requestedDocs]
              }
            end

            def documents_params
              payload = params[:documents_request] || params
              {
                documents: payload[:documents],
                notes: payload[:notes]
              }
            end

            def close_params
              payload = params[:close] || params
              {
                outcome: payload[:outcome],
                not_sold_reason: payload[:not_sold_reason] || payload[:notSoldReason],
                reason_notes: payload[:reason_notes] || payload[:reasonNotes]
              }
            end
          end
        end
      end
    end
  end
end
