# frozen_string_literal: true

FactoryBot.define do
  factory :ottiv_finance_negotiation, class: 'OttivFinanceNegotiation' do
    account
    status { 'submitted' }
    priority { 'medium' }
    finance_conversation_linked { false }
    customer do
      {
        'cpf' => '12345678901',
        'birthDate' => '1990-01-01',
        'hasCnh' => true,
        'name' => 'Cliente Teste'
      }
    end
    conditions do
      {
        'vehiclePrice' => 80_000,
        'downPayment' => 10_000,
        'financedAmount' => 70_000,
        'financingType' => 'cdc',
        'hasCnh' => true
      }
    end
    submitted_at { Time.current }

    transient do
      owner { nil }
    end

    after(:build) do |negotiation, evaluator|
      user = evaluator.owner || create(:user, account: negotiation.account)
      negotiation.created_by_id = user.id
      negotiation.updated_by_id = user.id
    end
  end
end
