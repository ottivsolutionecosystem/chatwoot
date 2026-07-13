# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Ottiv Finance Negotiations API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: 'administrator') }
  let(:seller) { create(:user, account: account, role: 'agent') }
  let(:other_seller) { create(:user, account: account, role: 'agent') }
  let(:fi_agent) { create(:user, account: account, role: 'agent') }

  let!(:seller_team) { create(:team, account: account, name: 'vendedores') }
  let!(:fi_team) { create(:team, account: account, name: 'fi') }

  before do
    allow(Config).to receive(:find_by).with(account_id: account.id).and_return(
      instance_double(
        Config,
        team_seller_id: seller_team.id,
        team_credit_analyst_id: fi_team.id
      )
    )
    seller_team.add_members([seller.id])
    fi_team.add_members([fi_agent.id])
  end

  def auth_headers(user)
    user.create_new_auth_token
  end

  def base_path
    "/api/ottiv/v1/accounts/#{account.id}/ottiv_finance_negotiations"
  end

  describe 'GET index' do
    let!(:own_negotiation) do
      create(:ottiv_finance_negotiation, account: account, owner: seller)
    end
    let!(:other_negotiation) do
      create(:ottiv_finance_negotiation, account: account, owner: other_seller)
    end

    it 'admin vê todas as negociações' do
      get base_path, headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |n| n['id'] }
      expect(ids).to contain_exactly(own_negotiation.id.to_s, other_negotiation.id.to_s)
    end

    it 'vendedor vê apenas negociações que criou' do
      get base_path, headers: auth_headers(seller)
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |n| n['id'] }
      expect(ids).to eq([own_negotiation.id.to_s])
    end

    it 'F&I vê todas as negociações' do
      get base_path, headers: auth_headers(fi_agent)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.length).to eq(2)
    end
  end

  describe 'POST create + F&I flow' do
    let(:payload) do
      {
        negotiation: {
          customer: {
            cpf: '52998224725',
            birthDate: '1985-05-15',
            hasCnh: true,
            name: 'João Silva'
          },
          conditions: {
            vehiclePrice: 90_000,
            downPayment: 15_000
          },
          submit: true
        }
      }
    end

    it 'cria negociação com ai_insight e permite parecer F&I' do
      post base_path, params: payload, headers: auth_headers(seller), as: :json
      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body['status']).to eq('submitted')
      expect(body['aiInsight']).to be_present
      expect(body['aiInsight']['approvalProbability']).to be_a(Numeric)

      negotiation_id = body['id']

      post "#{base_path}/#{negotiation_id}/opinions",
           params: {
             opinion: {
               bankCode: 'BV',
               bankName: 'BV Financeira',
               status: 'approved',
               opinionOutcome: 'approved_full',
               installmentOptions: [{ installments: 48, installmentValue: 1800 }]
             }
           },
           headers: auth_headers(fi_agent),
           as: :json

      expect(response).to have_http_status(:ok)
      opinion_body = response.parsed_body
      expect(opinion_body['offers'].length).to eq(1)
      expect(opinion_body['offers'].first['bankCode']).to eq('BV')

      post "#{base_path}/#{negotiation_id}/close",
           params: { close: { outcome: 'sold', reasonNotes: 'Fechou na loja' } },
           headers: auth_headers(fi_agent),
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['status']).to eq('closed')
      expect(response.parsed_body['closureOutcome']).to eq('sold')
    end

    it 'vendedor não pode lançar parecer' do
      post base_path, params: payload, headers: auth_headers(seller), as: :json
      negotiation_id = response.parsed_body['id']

      post "#{base_path}/#{negotiation_id}/opinions",
           params: {
             opinion: {
               bankCode: 'BV',
               bankName: 'BV Financeira',
               status: 'approved',
               opinionOutcome: 'approved_full'
             }
           },
           headers: auth_headers(seller),
           as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'vendedor não acessa negociação de outro vendedor' do
      negotiation = create(
        :ottiv_finance_negotiation,
        account: account,
        owner: other_seller
      )

      get "#{base_path}/#{negotiation.id}", headers: auth_headers(seller)
      expect(response).to have_http_status(:not_found)
    end
  end
end
