FactoryBot.define do
  factory :notification do
    association :user
    kind { :created }
    read { false }
    payload { {} }
  end
end
