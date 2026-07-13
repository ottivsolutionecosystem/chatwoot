# frozen_string_literal: true

module Ottiv::Core::Services::Finance
  class ComputeStatusService
    def self.call(negotiation)
      offers = negotiation.offers.to_a
      return negotiation.status if offers.empty?

      has_approved = offers.any? { |o| o.status == 'approved' }
      has_rejected = offers.all? { |o| %w[rejected expired].include?(o.status) }
      has_in_analysis = offers.any? { |o| %w[in_analysis sending not_sent].include?(o.status) }
      has_docs_required = offers.any? { |o| o.status == 'docs_required' }

      status = if has_approved && !has_in_analysis
                 'approved'
               elsif has_rejected && offers.any? && !has_approved
                 'rejected'
               elsif has_in_analysis
                 'querying'
               elsif has_approved
                 'partial'
               elsif has_docs_required
                 'partial'
               else
                 negotiation.status
               end

      negotiation.update!(status: status) if negotiation.status != status
      status
    end
  end
end
