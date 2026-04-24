# frozen_string_literal: true

FactoryBot.define do
  factory :ottiv_portal, class: 'OttivPortal' do
    account
    sequence(:name) { |n| "Portal #{n}" }
    sequence(:slug) { |n| "portal-#{n}" }
    source_id { '10' }
    active { true }
  end
end
