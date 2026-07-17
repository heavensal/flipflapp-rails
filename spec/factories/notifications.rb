FactoryBot.define do
  factory :notification do
    association :user
    kind { :invited }
    read { false }
    payload { {} }
  end
end
