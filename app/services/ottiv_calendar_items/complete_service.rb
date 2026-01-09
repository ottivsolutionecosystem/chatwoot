class OttivCalendarItems::CompleteService
  attr_reader :calendar_item

  def initialize(calendar_item:)
    @calendar_item = calendar_item
  end

  def perform
    ActiveRecord::Base.transaction do
      # Remove reminders automáticos não enviados (canal 'push')
      # Mantém reminders manuais que já foram enviados para histórico
      @calendar_item.ottiv_reminders
                     .where(channel: 'push', sent: false)
                     .destroy_all

      # Atualiza status para done
      @calendar_item.update!(status: :done)
      @calendar_item.reload
    end
  end
end

