class Api::V1::Accounts::OttivPortalsDashboardController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    portals = Current.account.ottiv_portals.active
    portals = portals.where(id: params[:portal_id]) if params[:portal_id].present?

    dashboard_data = portals.map do |portal|
      calculate_portal_kpis(portal, start_date, end_date)
    end

    aggregated_kpis = calculate_aggregated_kpis(portals, start_date, end_date)

    render json: {
      period: {
        start_date: start_date.to_s,
        end_date: end_date.to_s
      },
      portals: dashboard_data,
      aggregated: aggregated_kpis
    }
  rescue ArgumentError
    render json: { error: 'Invalid date format. Use YYYY-MM-DD' }, status: :unprocessable_entity
  end

  private

  def check_authorization
    check_admin_authorization?
  end

  def calculate_portal_kpis(portal, start_date, end_date)
    costs = OttivPortalCost.joins(:ottiv_portal)
                           .where(ottiv_portals: { id: portal.id })
                           .where('reference_period_start <= ? AND reference_period_end >= ?', end_date, start_date)

    total_costs = costs.sum(:amount).to_f

    source_id_value = if portal.source_id.present? && portal.source_id.to_s.match?(/\A\d+\z/)
                        portal.source_id.to_i
                      end

    deals = []
    if source_id_value
      deals_query = <<-SQL.squish
        SELECT d.id
        FROM deals d
        WHERE d.account_id = #{Current.account.id}
          AND d.source_id = #{source_id_value}
          AND d.delete_at IS NULL
      SQL

      deals = ActiveRecord::Base.connection.execute(deals_query).to_a
    end

    deal_ids = deals.map { |d| d['id'] }
    total_revenue = 0.0
    deals_count = deal_ids.count

    if deal_ids.any?
      products_query = <<-SQL.squish
        SELECT SUM(dp.price) AS total_price
        FROM deal_products dp
        WHERE dp.deal_id IN (#{deal_ids.join(',')})
      SQL

      result = ActiveRecord::Base.connection.execute(products_query).first
      total_revenue = result['total_price'].to_f if result && result['total_price']
    end

    roi = total_revenue - total_costs
    roi_percentage = total_costs.positive? ? ((roi / total_costs) * 100) : 0
    average_deal_value = deals_count.positive? ? (total_revenue / deals_count) : 0

    {
      portal: {
        id: portal.id,
        name: portal.name,
        slug: portal.slug,
        source_id: portal.source_id
      },
      costs: {
        total: total_costs,
        count: costs.count,
        by_type: costs.joins(:ottiv_cost_type)
                      .group('ottiv_cost_types.name', 'ottiv_cost_types.category')
                      .sum(:amount)
                      .map { |(name, category), amount| { type: name, category: category, amount: amount.to_f } }
      },
      revenue: {
        total: total_revenue,
        deals_count: deals_count,
        average_deal_value: average_deal_value
      },
      kpis: {
        roi: roi,
        roi_percentage: roi_percentage.round(2),
        cost_per_deal: deals_count.positive? ? (total_costs / deals_count) : 0,
        revenue_per_cost: total_costs.positive? ? (total_revenue / total_costs) : 0
      }
    }
  end

  def calculate_aggregated_kpis(portals, start_date, end_date)
    portal_ids = portals.pluck(:id)

    total_costs = if portal_ids.any?
                    OttivPortalCost.joins(:ottiv_portal)
                                   .where(ottiv_portals: { id: portal_ids })
                                   .where('reference_period_start <= ? AND reference_period_end >= ?', end_date, start_date)
                                   .sum(:amount).to_f
                  else
                    0.0
                  end

    source_ids = portals.where.not(source_id: nil).pluck(:source_id).map do |sid|
      sid.to_s.match?(/\A\d+\z/) ? sid.to_i : nil
    end.compact

    total_revenue = 0.0
    total_deals = 0

    if source_ids.any?
      deals_query = <<-SQL.squish
        SELECT d.id
        FROM deals d
        WHERE d.account_id = #{Current.account.id}
          AND d.source_id IN (#{source_ids.join(',')})
          AND d.delete_at IS NULL
      SQL

      deals = ActiveRecord::Base.connection.execute(deals_query).to_a
      deal_ids = deals.map { |d| d['id'] }
      total_deals = deal_ids.count

      if deal_ids.any?
        products_query = <<-SQL.squish
          SELECT SUM(dp.price) AS total_price
          FROM deal_products dp
          WHERE dp.deal_id IN (#{deal_ids.join(',')})
        SQL

        result = ActiveRecord::Base.connection.execute(products_query).first
        total_revenue = result['total_price'].to_f if result && result['total_price']
      end
    end

    total_roi = total_revenue - total_costs
    total_roi_percentage = total_costs.positive? ? ((total_roi / total_costs) * 100) : 0

    portals_count = portals.count

    {
      total_costs: total_costs,
      total_revenue: total_revenue,
      total_roi: total_roi,
      total_roi_percentage: total_roi_percentage.round(2),
      total_deals: total_deals,
      portals_count: portals_count,
      average_cost_per_portal: portals_count.positive? ? (total_costs / portals_count) : 0,
      average_revenue_per_portal: portals_count.positive? ? (total_revenue / portals_count) : 0
    }
  end
end

class Api::V1::Accounts::OttivPortalsDashboardController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    portals = Current.account.ottiv_portals.active
    portals = portals.where(id: params[:portal_id]) if params[:portal_id].present?

    dashboard_data = portals.map do |portal|
      calculate_portal_kpis(portal, start_date, end_date)
    end

    aggregated_kpis = calculate_aggregated_kpis(portals, start_date, end_date)

    render json: {
      period: {
        start_date: start_date.to_s,
        end_date: end_date.to_s
      },
      portals: dashboard_data,
      aggregated: aggregated_kpis
    }
  rescue ArgumentError
    render json: { error: 'Invalid date format. Use YYYY-MM-DD' }, status: :unprocessable_entity
  end

  private

  def check_authorization
    check_admin_authorization?
  end

  def calculate_portal_kpis(portal, start_date, end_date)
    costs = OttivPortalCost.joins(:ottiv_portal)
                           .where(ottiv_portals: { id: portal.id })
                           .where('reference_period_start <= ? AND reference_period_end >= ?', end_date, start_date)

    total_costs = costs.sum(:amount).to_f

    source_id_value = if portal.source_id.present? && portal.source_id.to_s.match?(/\A\d+\z/)
                        portal.source_id.to_i
                      end

    deals = []
    if source_id_value
      deals_query = <<-SQL.squish
        SELECT d.id
        FROM deals d
        WHERE d.account_id = #{Current.account.id}
          AND d.source_id = #{source_id_value}
          AND d.delete_at IS NULL
      SQL

      deals = ActiveRecord::Base.connection.execute(deals_query).to_a
    end

    deal_ids = deals.map { |d| d['id'] }
    total_revenue = 0.0
    deals_count = deal_ids.count

    if deal_ids.any?
      products_query = <<-SQL.squish
        SELECT SUM(dp.price) AS total_price
        FROM deal_products dp
        WHERE dp.deal_id IN (#{deal_ids.join(',')})
      SQL

      result = ActiveRecord::Base.connection.execute(products_query).first
      total_revenue = result['total_price'].to_f if result && result['total_price']
    end

    roi = total_revenue - total_costs
    roi_percentage = total_costs.positive? ? ((roi / total_costs) * 100) : 0
    average_deal_value = deals_count.positive? ? (total_revenue / deals_count) : 0

    {
      portal: {
        id: portal.id,
        name: portal.name,
        slug: portal.slug,
        source_id: portal.source_id
      },
      costs: {
        total: total_costs,
        count: costs.count,
        by_type: costs.joins(:ottiv_cost_type)
                      .group('ottiv_cost_types.name', 'ottiv_cost_types.category')
                      .sum(:amount)
                      .map { |(name, category), amount| { type: name, category: category, amount: amount.to_f } }
      },
      revenue: {
        total: total_revenue,
        deals_count: deals_count,
        average_deal_value: average_deal_value
      },
      kpis: {
        roi: roi,
        roi_percentage: roi_percentage.round(2),
        cost_per_deal: deals_count.positive? ? (total_costs / deals_count) : 0,
        revenue_per_cost: total_costs.positive? ? (total_revenue / total_costs) : 0
      }
    }
  end

  def calculate_aggregated_kpis(portals, start_date, end_date)
    portal_ids = portals.pluck(:id)

    total_costs = if portal_ids.any?
                    OttivPortalCost.joins(:ottiv_portal)
                                   .where(ottiv_portals: { id: portal_ids })
                                   .where('reference_period_start <= ? AND reference_period_end >= ?', end_date, start_date)
                                   .sum(:amount).to_f
                  else
                    0.0
                  end

    source_ids = portals.where.not(source_id: nil).pluck(:source_id).map do |sid|
      sid.to_s.match?(/\A\d+\z/) ? sid.to_i : nil
    end.compact

    total_revenue = 0.0
    total_deals = 0

    if source_ids.any?
      deals_query = <<-SQL.squish
        SELECT d.id
        FROM deals d
        WHERE d.account_id = #{Current.account.id}
          AND d.source_id IN (#{source_ids.join(',')})
          AND d.delete_at IS NULL
      SQL

      deals = ActiveRecord::Base.connection.execute(deals_query).to_a
      deal_ids = deals.map { |d| d['id'] }
      total_deals = deal_ids.count

      if deal_ids.any?
        products_query = <<-SQL.squish
          SELECT SUM(dp.price) AS total_price
          FROM deal_products dp
          WHERE dp.deal_id IN (#{deal_ids.join(',')})
        SQL

        result = ActiveRecord::Base.connection.execute(products_query).first
        total_revenue = result['total_price'].to_f if result && result['total_price']
      end
    end

    total_roi = total_revenue - total_costs
    total_roi_percentage = total_costs.positive? ? ((total_roi / total_costs) * 100) : 0

    portals_count = portals.count

    {
      total_costs: total_costs,
      total_revenue: total_revenue,
      total_roi: total_roi,
      total_roi_percentage: total_roi_percentage.round(2),
      total_deals: total_deals,
      portals_count: portals_count,
      average_cost_per_portal: portals_count.positive? ? (total_costs / portals_count) : 0,
      average_revenue_per_portal: portals_count.positive? ? (total_revenue / portals_count) : 0
    }
  end
end
