FactoryBot.define do
  factory :ottiv_personal_canned_response, class: 'OttivPersonalCannedResponse' do
    account
    user { association :user, account: account }
    sequence(:short_code) { |n| "code-#{n}" }
    content { 'Conteúdo de teste' }
  end
end
