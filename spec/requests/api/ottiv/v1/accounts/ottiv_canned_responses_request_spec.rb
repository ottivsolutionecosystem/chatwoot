require 'rails_helper'

RSpec.describe 'Api::Ottiv::V1::Accounts::OttivCannedResponses', type: :request do
  let(:account) { create(:account) }
  let(:agent_a) { create(:user, account: account, role: :agent) }
  let(:agent_b) { create(:user, account: account, role: :agent) }

  let!(:shared) do
    create(:canned_response, account: account, short_code: 'ola', content: 'Olá compartilhado')
  end
  let!(:personal_a) do
    create(:ottiv_personal_canned_response, account: account, user: agent_a,
                                            short_code: 'pessoal', content: 'Pessoal do A')
  end
  let!(:personal_b) do
    create(:ottiv_personal_canned_response, account: account, user: agent_b,
                                            short_code: 'pessoal', content: 'Pessoal do B')
  end

  describe 'GET /api/ottiv/v1/accounts/:account_id/ottiv_canned_responses' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/ottiv/v1/accounts/#{account.id}/ottiv_canned_responses"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as agent_a' do
      let(:headers) { agent_a.create_new_auth_token }

      it 'returns shared + personal responses of agent_a' do
        get "/api/ottiv/v1/accounts/#{account.id}/ottiv_canned_responses",
            headers: headers, as: :json

        expect(response).to have_http_status(:success)
        short_codes = response.parsed_body.map { |r| r['short_code'] }
        expect(short_codes).to include('ola', 'pessoal')
      end

      it 'does not include personal responses of agent_b' do
        get "/api/ottiv/v1/accounts/#{account.id}/ottiv_canned_responses",
            headers: headers, as: :json

        results = response.parsed_body
        personal_results = results.select { |r| r['personal'] == true }
        contents = personal_results.map { |r| r['content'] }
        expect(contents).to include('Pessoal do A')
        expect(contents).not_to include('Pessoal do B')
      end

      it 'personal takes precedence over shared when short_code clashes' do
        create(:ottiv_personal_canned_response, account: account, user: agent_a,
                                               short_code: 'ola', content: 'Meu próprio Olá')

        get "/api/ottiv/v1/accounts/#{account.id}/ottiv_canned_responses",
            headers: headers, as: :json

        ola_entries = response.parsed_body.select { |r| r['short_code'] == 'ola' }
        expect(ola_entries.length).to eq(1)
        expect(ola_entries.first['personal']).to be true
        expect(ola_entries.first['content']).to eq('Meu próprio Olá')
      end

      it 'filters by search param' do
        get "/api/ottiv/v1/accounts/#{account.id}/ottiv_canned_responses",
            params: { search: 'pessoal' },
            headers: headers, as: :json

        short_codes = response.parsed_body.map { |r| r['short_code'] }
        expect(short_codes).to include('pessoal')
        expect(short_codes).not_to include('ola')
      end

      it 'returns only personal when personal_only=true' do
        get "/api/ottiv/v1/accounts/#{account.id}/ottiv_canned_responses",
            params: { personal_only: 'true' },
            headers: headers, as: :json

        results = response.parsed_body
        expect(results.all? { |r| r['personal'] == true }).to be true
        short_codes = results.map { |r| r['short_code'] }
        expect(short_codes).not_to include('ola')
      end

      it 'returns only shared when shared_only=true' do
        get "/api/ottiv/v1/accounts/#{account.id}/ottiv_canned_responses",
            params: { shared_only: 'true' },
            headers: headers, as: :json

        results = response.parsed_body
        expect(results.all? { |r| r['personal'] == false }).to be true
        short_codes = results.map { |r| r['short_code'] }
        expect(short_codes).to include('ola')
        expect(short_codes).not_to include('pessoal')
      end
    end
  end
end
