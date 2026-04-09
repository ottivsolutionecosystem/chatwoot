# frozen_string_literal: true

class OttivCallPolicy < ApplicationPolicy
  def sync?
    account_user.present? && (account_user.administrator? || account_user.agent?)
  end

  def index?
    sync?
  end

  def summary?
    index?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(account_id: account&.id)
    end
  end
end

OttivCallPolicy.prepend_mod_with('OttivCallPolicy')
