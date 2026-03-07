module Ottiv::Core
  module Controllers
    module Api
      module V1
        module Accounts
          class SkillQueueController < ::Api::V1::Accounts::BaseController
            def next
              skill = resolve_skill
              unless skill
                return render_structured_error(
                  status: :not_found,
                  code: 'skill_not_found',
                  message: 'Skill nao encontrada ou inativa'
                )
              end

              rotate_queue = ActiveModel::Type::Boolean.new.cast(params[:rotate_queue])
              selected_agent = rotate_queue ? select_and_rotate(skill) : peek_next(skill)

              unless selected_agent
                return render_structured_error(
                  status: :not_found,
                  code: 'no_active_agent_in_skill_queue',
                  message: 'Nao existe agente ativo para esta skill'
                )
              end

              assignment = assign_conversation_if_requested(selected_agent.agent_id)
              return if response_body.present?

              render json: {
                success: true,
                account_id: Current.account.id,
                skill: {
                  id: skill.id,
                  type: skill.type,
                  name: skill.name
                },
                agent: {
                  skill_agent_id: selected_agent.id,
                  agent_id: selected_agent.agent_id,
                  name: selected_agent.agent&.name,
                  email: selected_agent.agent&.email,
                  availability_status: selected_agent.agent&.availability_status
                },
                rotated: rotate_queue,
                last_assigned_at: selected_agent.last_assigned_at,
                assignment: assignment
              }
            rescue ActionController::ParameterMissing => e
              render_structured_error(
                status: :unprocessable_entity,
                code: 'invalid_payload',
                message: e.message
              )
            rescue StandardError => e
              render_structured_error(
                status: :unprocessable_entity,
                code: 'skill_queue_unexpected_error',
                message: e.message
              )
            end

            private

            def resolve_skill
              skill_params = params.require(:skill).permit(:type, :name)
              skill_type = skill_params[:type].to_s.strip.downcase
              skill_name = skill_params[:name].to_s.strip.downcase

              Current.account.ottiv_skills.active.find_by(type: skill_type, name: skill_name)
            end

            def peek_next(skill)
              queue_scope(skill).lru_order.first
            end

            def select_and_rotate(skill)
              selected_agent = nil

              OttivSkillAgent.transaction do
                selected_agent = queue_scope(skill).lru_order.lock('FOR UPDATE SKIP LOCKED').first
                selected_agent&.update!(last_assigned_at: Time.current)
              end

              selected_agent
            end

            def queue_scope(skill)
              Current.account.ottiv_skill_agents.active.includes(:agent).for_skill(skill.id)
            end

            def assign_conversation_if_requested(agent_id)
              conversation_id = params[:conversation_id]
              return { performed: false } if conversation_id.blank?

              conversation = Current.account.conversations.find_by(display_id: conversation_id)
              unless conversation
                render_structured_error(
                  status: :not_found,
                  code: 'conversation_not_found',
                  message: 'Conversa nao encontrada para atribuicao',
                  conversation_id: conversation_id
                )
                return { performed: false }
              end

              agent = Current.account.users.find_by(id: agent_id)
              unless agent
                render_structured_error(
                  status: :unprocessable_entity,
                  code: 'agent_not_found_in_account',
                  message: 'Agente selecionado nao encontrado nesta conta',
                  conversation_id: conversation.display_id
                )
                return { performed: false }
              end

              # Segue o mesmo fluxo do endpoint nativo de assignments:
              # conversation.assignee = agent e conversation.save!
              conversation.assignee = agent
              conversation.save!

              {
                performed: true,
                conversation_id: conversation.display_id,
                assignee_id: agent.id
              }
            rescue StandardError => e
              render_structured_error(
                status: :unprocessable_entity,
                code: 'conversation_assignment_failed',
                message: "Falha ao atribuir conversa automaticamente: #{e.message}",
                conversation_id: conversation_id
              )
              { performed: false }
            end

            def render_structured_error(status:, code:, message:, conversation_id: nil)
              note_result = create_error_private_note(conversation_id, code, message)
              render json: {
                success: false,
                error: {
                  code: code,
                  message: message
                },
                conversation_note: note_result
              }, status: status
            end

            def create_error_private_note(conversation_id, error_code, error_message)
              return { performed: false } if conversation_id.blank?

              conversation = Current.account.conversations.find_by(display_id: conversation_id)
              return { performed: false } if conversation.blank?

              note_content = "[OTTIV][AUTO-ASSIGN][ERRO:#{error_code}] #{error_message}"
              Messages::MessageBuilder.new(
                Current.user,
                conversation,
                { content: note_content, private: true }
              ).perform

              { performed: true, conversation_id: conversation.display_id, message: note_content }
            rescue StandardError
              { performed: false }
            end
          end
        end
      end
    end
  end
end
