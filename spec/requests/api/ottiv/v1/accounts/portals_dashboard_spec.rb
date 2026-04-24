# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /api/ottiv/v1/accounts/:account_id/ottiv_portals/dashboard', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: 'administrator') }
  let(:headers) { user.create_new_auth_token }

  let!(:portal) do
    create(:ottiv_portal, account: account, source_id: '42', active: true)
  end

  def get_dashboard(extra_headers = headers)
    get "/api/ottiv/v1/accounts/#{account.id}/ottiv_portals/dashboard",
        headers: extra_headers
  end

  context 'sem autenticação' do
    it 'retorna 401' do
      get_dashboard({})
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'com administrador autenticado' do
    it 'monta SQL de deals com JOIN em pipeline_stages e is_final = TRUE' do
      allow(ActiveRecord::Base.connection).to receive(:select_all).and_wrap_original do |original, sql, *rest|
        s = sql.to_s
        if s.include?('FROM deals d') && s.include?('pipeline_stages')
          expect(s).to include('INNER JOIN pipeline_stages ps ON ps.id = d.stage_id AND ps.account_id = d.account_id')
          expect(s).to include('ps.is_final = TRUE')
          []
        else
          original.call(sql, *rest)
        end
      end

      get_dashboard

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['portals'].length).to eq(1)
      row = body['portals'].find { |p| p['portal']['id'] == portal.id }
      expect(row['revenue']['total']).to eq(0.0)
      expect(row['revenue']['deals_count']).to eq(0)
    end

    it 'soma deal_products apenas para deal_ids retornados pela query com estágio final' do
      allow(ActiveRecord::Base.connection).to receive(:select_all).and_wrap_original do |original, sql, *rest|
        s = sql.to_s
        if s.include?('FROM deals d') && s.include?('pipeline_stages')
          [{ 'id' => 99 }]
        else
          original.call(sql, *rest)
        end
      end

      allow(ActiveRecord::Base.connection).to receive(:select_one).and_wrap_original do |original, sql, *rest|
        s = sql.to_s
        if s.include?('deal_products') && s.include?('SUM(dp.price)')
          { 'total_price' => '250.25' }
        else
          original.call(sql, *rest)
        end
      end

      get_dashboard

      expect(response).to have_http_status(:ok)
      portal_payload = response.parsed_body['portals'].find { |p| p['portal']['id'] == portal.id }
      expect(portal_payload['revenue']['total']).to eq(250.25)
      expect(portal_payload['revenue']['deals_count']).to eq(1)
      expect(portal_payload['revenue']['average_deal_value']).to eq(250.25)
    end
  end
end
