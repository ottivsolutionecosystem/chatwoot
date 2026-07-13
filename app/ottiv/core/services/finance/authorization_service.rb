# frozen_string_literal: true

module Ottiv::Core::Services::Finance
  class AuthorizationService
    class UnauthorizedError < StandardError; end
    class ForbiddenError < StandardError; end

    FI_ACTIONS = %i[
      query_banks add_opinion update_opinion request_documents close
    ].freeze

    def initialize(user:, account:)
      @user = user
      @account = account
      @config = Config.find_by(account_id: account.id)
    end

    attr_reader :user, :account

    def admin?
      @user.administrator?
    end

    def fi?
      return true if admin?

      team_id = @config&.team_credit_analyst_id
      return false if team_id.blank?

      @user.teams.exists?(id: team_id, account_id: @account.id)
    end

    def seller?
      return true if fi?

      team_id = @config&.team_seller_id
      return false if team_id.blank?

      @user.teams.exists?(id: team_id, account_id: @account.id)
    end

    def can_access_module?
      admin? || fi? || seller?
    end

    def can_manage_fi_actions?
      fi?
    end

    def can_create_negotiation?
      can_access_module?
    end

    def scoped_negotiations
      base = OttivFinanceNegotiation.for_account(@account.id)
                                    .includes(
                                      :offers,
                                      { offers: :installments },
                                      :documents,
                                      :timeline_events
                                    )

      return base if admin? || fi?
      return base.where(created_by_id: @user.id) if seller?

      OttivFinanceNegotiation.none
    end

    def find_negotiation!(id)
      negotiation = scoped_negotiations.find_by(id: id)
      raise ActiveRecord::RecordNotFound, 'Negociação não encontrada' if negotiation.nil?

      negotiation
    end

    def authorize_fi_action!(action = nil)
      raise ForbiddenError, 'Acesso negado' unless can_manage_fi_actions?
    end

    def authorize_access!
      raise ForbiddenError, 'Acesso negado ao módulo financeiro' unless can_access_module?
    end

    def authorize_create!
      raise ForbiddenError, 'Acesso negado' unless can_create_negotiation?
    end

    def creator_name
      @user.available_name.presence || @user.name
    end
  end
end
