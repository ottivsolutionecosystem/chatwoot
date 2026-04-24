# frozen_string_literal: true

class AddDefaultAmountToOttivPortalCosts < ActiveRecord::Migration[7.0]
  def change
    change_column_default :ottiv_portal_costs, :amount, from: nil, to: 0
  end
end
