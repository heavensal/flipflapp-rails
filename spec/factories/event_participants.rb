FactoryBot.define do
  factory :event_participant do
    association :user
    association :event

    event_team { event.event_teams.first }
  end
end
