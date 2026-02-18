module Ottiv::Core
module Controllers
    module Api
      module V1
        module Accounts
          class SearchController < ::Api::V1::Accounts::BaseController
            def index
              result = ottiv_search_service.perform
              @results = result[:results]
              @messages = result[:messages]
              @meta = result[:meta]
              render 'api/v1/accounts/ottiv_search/index'
            rescue StandardError => e
              Rails.logger.error("❌ [OttivSearch] Erro ao buscar: #{e.class} - #{e.message}")
              Rails.logger.error(e.backtrace.join("\n"))
              render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end

            private

            def ottiv_search_service
              @ottiv_search_service ||= Core::Services::SearchService.new(
                current_user: Current.user,
                current_account: Current.account,
                params: ottiv_search_params
              )
            end

            def ottiv_search_params
              # Aceitar parâmetros do body JSON + query params
              body_params = {}

              if request.content_type&.include?('json') && request.body.present?
                begin
                  body_content = request.body.read
                  request.body.rewind
                  body_params = body_content.present? ? JSON.parse(body_content) : {}
                rescue JSON::ParserError => e
                  Rails.logger.error("❌ [OttivSearch] Erro ao parsear JSON: #{e.message}")
                  body_params = {}
                end
              end

              # Query params - incluir filtros
              query_params = params.permit(
                :q, :searchTerm, :page, :status, :conversation_type, :assignee_type, :sort_by,
                inbox_ids: [], label_titles: [], assignee_ids: [], include_unassigned: []
              ).to_h

              # Merge body e query params
              body_hash = body_params.is_a?(Hash) ? body_params : {}
              merged_params = body_hash.with_indifferent_access.merge(query_params.with_indifferent_access)

              # Normalizar searchTerm para q
              if merged_params[:searchTerm].present? && merged_params[:q].blank?
                merged_params[:q] = merged_params[:searchTerm]
              end

              # Valores padrão
              merged_params[:status] ||= 'all'
              merged_params[:sort_by] ||= 'last_activity_at_desc'
              merged_params[:page] = (merged_params[:page] || 1).to_i
              merged_params[:page] = 1 if merged_params[:page] < 1

              # Normalizar arrays
              merged_params[:inbox_ids] = normalize_array(merged_params[:inbox_ids]) if merged_params.key?(:inbox_ids)
              merged_params[:label_titles] = normalize_array(merged_params[:label_titles]) if merged_params.key?(:label_titles)
              merged_params[:assignee_ids] = normalize_array(merged_params[:assignee_ids]) if merged_params.key?(:assignee_ids)

              # Normalizar include_unassigned para boolean
              if merged_params.key?(:include_unassigned)
                include_unassigned = merged_params[:include_unassigned]
                merged_params[:include_unassigned] = case include_unassigned
                                                     when true, 'true', 1, '1', 'yes'
                                                       true
                                                     else
                                                       false
                                                     end
              end

              merged_params.with_indifferent_access
            end

            def normalize_array(value)
              return [] if value.blank?
              return value if value.is_a?(Array)
              [value].flatten.compact
            end
          end
        end
      end
    end
  end
end
