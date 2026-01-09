class OttivCalendarItems::UpdateService
  attr_reader :calendar_item, :params

  def initialize(calendar_item:, params:)
    @calendar_item = calendar_item
    @params = params
  end

  def perform
    ActiveRecord::Base.transaction do
      # Verificar se start_at está nos params (indica que pode ter mudado)
      has_start_at_param = params[:start_at].present?

      # Atualizar o calendar item
      update_calendar_item

      # Atualizar contatos se fornecidos
      update_contacts if params[:contact_ids].present?

      # Atualizar participantes se fornecidos
      update_participants if params[:participant_ids].present?

      # Se start_at foi enviado nos params, sempre recriar reminders automáticos
      # (mesmo que não tenha mudado, garante consistência)
      if has_start_at_param || params[:reminders].present?
        update_reminders(has_start_at_param)
      end

      calendar_item.reload
    end
  end

  private

  def update_calendar_item
    calendar_item.update!(calendar_item_params)
  end

  def update_contacts
    # Remove todos os contatos existentes
    calendar_item.ottiv_calendar_item_contacts.destroy_all

    # Adiciona os novos contatos
    return unless params[:contact_ids].is_a?(Array)

    params[:contact_ids].each do |contact_id|
      calendar_item.ottiv_calendar_item_contacts.create!(contact_id: contact_id)
    end
  end

  def update_participants
    # Remove todos os participantes existentes (exceto o criador, que será readicionado)
    calendar_item.ottiv_calendar_item_participants
                 .where.not(user_id: calendar_item.user_id)
                 .destroy_all

    # Adiciona os novos participantes
    participant_ids = params[:participant_ids] || []
    participant_ids = participant_ids.to_a if participant_ids.respond_to?(:to_a)

    # Sempre adicionar o criador como participante
    participant_ids = (participant_ids + [calendar_item.user_id]).uniq

    participant_ids.each do |user_id|
      next if calendar_item.ottiv_calendar_item_participants.exists?(user_id: user_id)

      calendar_item.ottiv_calendar_item_participants.create!(user_id: user_id)
    end
  end

  def update_reminders(should_recreate_automatic)
    # Se start_at foi enviado, remover reminders automáticos antigos e recriar
    if should_recreate_automatic
      # Remove apenas reminders automáticos (canal 'push') que ainda não foram enviados
      calendar_item.ottiv_reminders
                   .where(channel: 'push', sent: false)
                   .destroy_all

      # Recria reminders automáticos se o item ainda é do tipo reminder/event
      create_automatic_reminders if calendar_item.reminder? || calendar_item.event?
    end

    # Atualizar reminders manuais se fornecidos
    if params[:reminders].is_a?(Array)
      # Remove reminders manuais (não push) que ainda não foram enviados
      calendar_item.ottiv_reminders
                   .where.not(channel: 'push')
                   .where(sent: false)
                   .destroy_all

      # Cria novos reminders manuais
      params[:reminders].each do |reminder_data|
        # Converter string ISO para Time explicitamente para garantir timezone correto
        notify_at = parse_notify_at(reminder_data[:notify_at])
        
        calendar_item.ottiv_reminders.create!(
          notify_at: notify_at,
          channel: reminder_data[:channel] || 'in_app'
        )
      end
    end
  end

  def create_automatic_reminders
    # Recarregar para garantir que temos o start_at mais recente
    calendar_item.reload
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
          channel: 'push'
        )
      end
    end
  end

  def calendar_item_params
    params.permit(
      :item_type,
      :title,
      :description,
      :start_at,
      :end_at,
      :location,
      :status,
      :conversation_id
    )
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

