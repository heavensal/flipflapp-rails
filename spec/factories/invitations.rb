FactoryBot.define do
  factory :invitation do
    association :event
    association :user
  end
end
