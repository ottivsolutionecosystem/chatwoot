module Ottiv
  module Core
  module Jobs
    class CompletePastItemsJob < ApplicationJob
      queue_as :ottiv_core_low

      def perform
        Rails.logger.info 'Ottiv::Core::Jobs::CompletePastItemsJob: Starting to auto-complete past items'
        
        completed_count = 0
        
        OttivCalendarItem.active.where('end_at < ? OR (end_at IS NULL AND start_at < ?)', 
                                       1.hour.ago, 1.hour.ago).find_each do |item|
          item.complete!
          completed_count += 1
          Rails.logger.info "Ottiv::Core::Jobs::CompletePastItemsJob: Completed item #{item.id} - #{item.title}"
        rescue StandardError => e
          Rails.logger.error "Ottiv::Core::Jobs::CompletePastItemsJob: Error completing item #{item.id}: #{e.message}"
        end
        
        Rails.logger.info "Ottiv::Core::Jobs::CompletePastItemsJob: Completed #{completed_count} items"
      end
    end
  end
end

  end
