# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /api/ottiv/v1/accounts/:account_id/ottiv_calls/resolve_call_conversation',
               type: :request do
  let(:account) { create(:account) }
  let(:user)    { create(:user, account: account, role: :agent) }
  let(:inbox)   { create(:inbox, account: account) }
  let(:headers) { user.create_new_auth_token }

  before do
    create(:inbox_member, user: user, inbox: inbox)
  end

  def post_resolve(params, auth_headers = headers)
    post "/api/ottiv/v1/accounts/#{account.id}/ottiv_calls/resolve_call_conversation",
         params: params, headers: auth_headers, as: :json
  end

  context 'sem autenticação' do
    it 'retorna 401' do
      post_resolve({ phone_number: '+5511999990001', inbox_id: inbox.id }, {})
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'com phone_number ausente' do
    it 'retorna 422' do
      post_resolve({ inbox_id: inbox.id })
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'com phone_number inválido' do
    it 'retorna 422' do
      post_resolve({ phone_number: 'nao_e_telefone', inbox_id: inbox.id })
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'com inbox_id inválido' do
    it 'retorna 404' do
      post_resolve({ phone_number: '+5511999990002', inbox_id: 999_999 })
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'quando agente não pertence à inbox' do
    let(:other_inbox) { create(:inbox, account: account) }

    it 'retorna 403' do
      post_resolve({ phone_number: '+5511999990003', inbox_id: other_inbox.id })
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'quando contato e conversa já existem' do
    let!(:contact) do
      create(:contact, account: account, phone_number: '+5511999990010')
    end
    let!(:conversation) do
      create(:conversation,
             account: account,
             inbox: inbox,
             contact: contact,
             assignee: user)
    end

    it 'retorna conversation_id da última conversa sem criar nova' do
      expect do
        post_resolve({ phone_number: '+5511999990010', inbox_id: inbox.id })
      end.not_to change(Conversation, :count)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['conversation_id']).to eq(conversation.display_id)
      expect(body['contact_id']).to eq(contact.id)
      expect(body['created_new_conversation']).to be(false)
    end

    it 'retorna a conversa mais recente quando há múltiplas' do
      older = create(:conversation,
                     account: account,
                     inbox: inbox,
                     contact: contact)
      older.update_columns(last_activity_at: 2.days.ago)
      conversation.update_columns(last_activity_at: 1.hour.ago)

      post_resolve({ phone_number: '+5511999990010', inbox_id: inbox.id })

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['conversation_id']).to eq(conversation.display_id)
    end
  end

  context 'quando contato existe mas não há conversa na inbox' do
    let!(:contact) do
      create(:contact, account: account, phone_number: '+5511999990020')
    end

    it 'cria nova conversa com assignee = usuário autenticado' do
      expect do
        post_resolve({ phone_number: '+5511999990020', inbox_id: inbox.id })
      end.to change(Conversation, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['created_new_conversation']).to be(true)
      expect(body['contact_id']).to eq(contact.id)

      new_conv = Conversation.find_by(display_id: body['conversation_id'])
      expect(new_conv).not_to be_nil
      expect(new_conv.assignee_id).to eq(user.id)
      expect(new_conv.inbox_id).to eq(inbox.id)
    end
  end

  context 'quando o contato não existe' do
    let(:phone) { '+5511999990030' }

    it 'cria contato, contact_inbox e conversa com assignee = usuário autenticado' do
      expect do
        post_resolve({ phone_number: phone, inbox_id: inbox.id,
                       contact_name: 'Chamador Desconhecido' })
      end.to change(Contact, :count).by(1)
         .and change(Conversation, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['created_new_conversation']).to be(true)

      new_contact = account.contacts.find_by(phone_number: phone)
      expect(new_contact).not_to be_nil
      expect(new_contact.name).to eq('Chamador Desconhecido')

      new_conv = Conversation.find_by(display_id: body['conversation_id'])
      expect(new_conv).not_to be_nil
      expect(new_conv.assignee_id).to eq(user.id)
      expect(new_conv.contact_id).to eq(new_contact.id)
    end

    it 'usa número formatado como nome quando contact_name não é passado' do
      post_resolve({ phone_number: phone, inbox_id: inbox.id })

      expect(response).to have_http_status(:ok)
      new_contact = account.contacts.find_by(phone_number: phone)
      expect(new_contact.name).not_to be_blank
    end
  end
end
