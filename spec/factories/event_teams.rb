FactoryBot.define do
  factory :event_team do
    association :event
    sequence(:name) { |n| "Equipe #{n}" }
  end
end
