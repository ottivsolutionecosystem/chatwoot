module Ottiv
  module Core
  module Services
    module CalendarItems
      class CreateService
          attr_reader :params, :user, :account

          def initialize(params:, user:, account:)
            @params = params
            @user = user
            @account = account
          end

          def perform
            ActiveRecord::Base.transaction do
              calendar_item = create_calendar_item
              create_contacts(calendar_item) if params[:contact_ids].present?
              create_participants(calendar_item) # Sempre cria, incluindo o criador
              create_reminders(calendar_item) # Sempre cria reminders automáticos para reminder/event

              # NOVO: Criar registros duplicados para cada participante
              create_duplicate_items_for_participants(calendar_item)

              # Notificar participantes após criação (notifica o registro original)
              Ottiv::Ottiv::Core::Jobs::NotifyParticipantsJob.perform_later(calendar_item.id)

              calendar_item
            end
          end

          private

          def create_calendar_item
            calendar_item = OttivCalendarItem.new(calendar_item_params)
            calendar_item.user = user
            calendar_item.account = account
            calendar_item.save!
            calendar_item
          end

          def create_contacts(calendar_item)
            return unless params[:contact_ids].is_a?(Array)

            params[:contact_ids].each do |contact_id|
              calendar_item.ottiv_calendar_item_contacts.create!(contact_id: contact_id)
            end
          end

          def create_participants(calendar_item)
            participant_ids = params[:participant_ids] || []
            participant_ids = participant_ids.to_a if participant_ids.respond_to?(:to_a)

            # Criar participantes apenas para os IDs fornecidos
            participant_ids.each do |user_id|
              calendar_item.ottiv_calendar_item_participants.create!(user_id: user_id)
            end
          end

          def create_reminders(calendar_item)
            # Reminders manuais (se fornecidos)
            if params[:reminders].is_a?(Array)
              params[:reminders].each do |reminder_data|
                # Converter string ISO para Time explicitamente para garantir timezone correto
                notify_at = parse_notify_at(reminder_data[:notify_at])
                
                calendar_item.ottiv_reminders.create!(
                  notify_at: notify_at,
                  channel: reminder_data[:channel] || 'in_app'
                )
              end
            end

            # Criar reminders automáticos para push (no start_at e 30, 15, 10, 5 minutos antes)
            # Apenas para items do tipo 'reminder' ou 'event'
            if calendar_item.reminder? || calendar_item.event?
              start_time = calendar_item.start_at

              # Garantir que start_time é um objeto Time válido
              unless start_time.is_a?(Time) || start_time.is_a?(ActiveSupport::TimeWithZone)
                Rails.logger.error("Invalid start_at: #{start_time.inspect}")
                return
              end

              # Criar reminder no exato momento do start_at (se ainda não passou)
              if start_time > Time.current
                calendar_item.ottiv_reminders.create!(
                  notify_at: start_time,
                  channel: 'push'
                )
              end

              # Criar reminders automáticos (25, 15, 10, 5 minutos antes)
              [25, 15, 10, 5].each do |minutes_before|
                notify_at = start_time - minutes_before.minutes

                # Só criar se o horário de notificação ainda não passou
                if notify_at > Time.current
                  calendar_item.ottiv_reminders.create!(
                    notify_at: notify_at,
                    channel: 'push' # Canal específico para push notifications automáticas
                  )
                end
              end
            end
          end

          def create_duplicate_items_for_participants(original_item)
            participant_ids = params[:participant_ids] || []
            participant_ids = participant_ids.to_a if participant_ids.respond_to?(:to_a)
            
            # Criar registros duplicados apenas para os participantes selecionados
            participant_ids.each do |participant_user_id|
              # Criar registro duplicado com user_id do participante
              duplicate = OttivCalendarItem.new(
                item_type: original_item.item_type,
                title: original_item.title,
                description: original_item.description,
                start_at: original_item.start_at,
                end_at: original_item.end_at,
                location: original_item.location,
                status: original_item.status,
                user_id: participant_user_id, # user_id do participante
                account_id: original_item.account_id,
                conversation_id: original_item.conversation_id
              )
              duplicate.save!
              
              # Copiar contatos para o duplicado
              original_item.contacts.each do |contact|
                duplicate.ottiv_calendar_item_contacts.create!(contact_id: contact.id)
              end
              
              # Copiar reminders automáticos para o duplicado
              original_item.ottiv_reminders.each do |reminder|
                duplicate.ottiv_reminders.create!(
                  notify_at: reminder.notify_at,
                  channel: reminder.channel
                )
              end
              
              # Copiar TODOS os participantes do item original para o duplicado
              # Assim cada registro mantém a referência de todos os envolvidos
              original_item.ottiv_calendar_item_participants.each do |participant|
                duplicate.ottiv_calendar_item_participants.create!(user_id: participant.user_id)
              end
              
              # Notificar o participante sobre seu registro duplicado
              Ottiv::Ottiv::Core::Jobs::NotifyParticipantsJob.perform_later(duplicate.id)
              
              Rails.logger.info "Created duplicate calendar_item #{duplicate.id} for participant #{participant_user_id}"
            end
          end

          def calendar_item_params
            permitted_params = params.permit(
              :item_type,
              :title,
              :description,
              :start_at,
              :end_at,
              :location,
              :status,
              :conversation_id
            )

            # Converter display_id para id real
            if permitted_params[:conversation_id].present?
              conversation = account.conversations.find_by(display_id: permitted_params[:conversation_id])
              if conversation
                permitted_params[:conversation_id] = conversation.id
              else
                raise ArgumentError, "Conversation with display_id #{permitted_params[:conversation_id]} not found"
              end
            end

            permitted_params
          end

          # Converte notify_at de string ISO para Time explicitamente
          # Garante que timezone seja tratado corretamente
          def parse_notify_at(notify_at_value)
            return notify_at_value if notify_at_value.nil?
            
            # Se já é um objeto Time, retornar como está
            return notify_at_value if notify_at_value.is_a?(Time) || notify_at_value.is_a?(ActiveSupport::TimeWithZone)
            
            # Se é string, converter para Time
            if notify_at_value.is_a?(String)
              # Tentar Time.zone.parse primeiro (respeita timezone configurada)
              parsed_time = Time.zone.parse(notify_at_value)
              return parsed_time if parsed_time
              
              # Fallback para Time.parse (UTC se string termina com Z)
              parsed_time = Time.parse(notify_at_value)
              return parsed_time.utc if notify_at_value.end_with?('Z')
              return parsed_time
            end
            
            # Se não conseguiu converter, retornar o valor original (Rails tentará converter)
            notify_at_value
          end
        end
      end
    end
end

  end
