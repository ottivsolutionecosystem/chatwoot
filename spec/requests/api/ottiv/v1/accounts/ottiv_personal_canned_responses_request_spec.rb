require 'rails_helper'

RSpec.describe 'Api::Ottiv::V1::Accounts::OttivPersonalCannedResponses', type: :request do
  let(:account) { create(:account) }
  let(:agent_a) { create(:user, account: account, role: :agent) }
  let(:agent_b) { create(:user, account: account, role: :agent) }

  describe 'POST /api/ottiv/v1/accounts/:account_id/ottiv_personal_canned_responses' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/ottiv/v1/accounts/#{account.id}/ottiv_personal_canned_responses"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      let(:headers) { agent_a.create_new_auth_token }

      it 'creates a personal canned response for current user' do
        params = { ottiv_personal_canned_response: { short_code: 'ola', content: 'Olá pessoal' } }
        post "/api/ottiv/v1/accounts/#{account.id}/ottiv_personal_canned_responses",
             params: params, headers: headers, as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body['short_code']).to eq('ola')
        expect(response.parsed_body['personal']).to be true
      end

      it 'associates with current user ignoring any user_id in payload' do
        params = { ottiv_personal_canned_response: { short_code: 'teste', content: 'X', user_id: agent_b.id } }
        post "/api/ottiv/v1/accounts/#{account.id}/ottiv_personal_canned_responses",
             params: params, headers: headers, as: :json

        expect(response).to have_http_status(:created)
        record = OttivPersonalCannedResponse.last
        expect(record.user_id).to eq(agent_a.id)
      end

      it 'returns 422 when short_code is duplicated for same user' do
        create(:ottiv_personal_canned_response, account: account, user: agent_a, short_code: 'dup')
        params = { ottiv_personal_canned_response: { short_code: 'dup', content: 'Outro' } }
        post "/api/ottiv/v1/accounts/#{account.id}/ottiv_personal_canned_responses",
             params: params, headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'allows same short_code for different users' do
        create(:ottiv_personal_canned_response, account: account, user: agent_b, short_code: 'shared-code')
        params = { ottiv_personal_canned_response: { short_code: 'shared-code', content: 'Meu' } }
        post "/api/ottiv/v1/accounts/#{account.id}/ottiv_personal_canned_responses",
             params: params, headers: headers, as: :json

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe 'PUT /api/ottiv/v1/accounts/:account_id/ottiv_personal_canned_responses/:id' do
    let!(:record_a) { create(:ottiv_personal_canned_response, account: account, user: agent_a, short_code: 'x') }
    let!(:record_b) { create(:ottiv_personal_canned_response, account: account, user: agent_b, short_code: 'y') }

    context 'when authenticated as agent_a' do
      let(:headers) { agent_a.create_new_auth_token }

      it 'updates own record' do
        put "/api/ottiv/v1/accounts/#{account.id}/ottiv_personal_canned_responses/#{record_a.id}",
            params: { ottiv_personal_canned_response: { content: 'Atualizado' } },
            headers: headers, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['content']).to eq('Atualizado')
      end

      it 'returns 404 when trying to update record belonging to agent_b' do
        put "/api/ottiv/v1/accounts/#{account.id}/ottiv_personal_canned_responses/#{record_b.id}",
            params: { ottiv_personal_canned_response: { content: 'Hack' } },
            headers: headers, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/ottiv/v1/accounts/:account_id/ottiv_personal_canned_responses/:id' do
    let!(:record_a) { create(:ottiv_personal_canned_response, account: account, user: agent_a) }
    let!(:record_b) { create(:ottiv_personal_canned_response, account: account, user: agent_b) }

    context 'when authenticated as agent_a' do
      let(:headers) { agent_a.create_new_auth_token }

      it 'destroys own record' do
        delete "/api/ottiv/v1/accounts/#{account.id}/ottiv_personal_canned_responses/#{record_a.id}",
               headers: headers, as: :json

        expect(response).to have_http_status(:no_content)
        expect(OttivPersonalCannedResponse.find_by(id: record_a.id)).to be_nil
      end

      it 'returns 404 when trying to delete record belonging to agent_b' do
        delete "/api/ottiv/v1/accounts/#{account.id}/ottiv_personal_canned_responses/#{record_b.id}",
               headers: headers, as: :json

        expect(response).to have_http_status(:not_found)
        expect(OttivPersonalCannedResponse.find_by(id: record_b.id)).not_to be_nil
      end
    end
  end
end
