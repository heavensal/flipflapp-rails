FactoryBot.define do
  factory :event_team do
    association :event
    sequence(:label) { |n| "Custom #{n}" }
    slot { :team_one }

    trait :team_one do
      slot { :team_one }
      label { I18n.t("event_team.slots.team_one.default_label") }
    end

    trait :team_two do
      slot { :team_two }
      label { I18n.t("event_team.slots.team_two.default_label") }
    end

    trait :bench do
      slot { :bench }
      label { I18n.t("event_team.slots.bench.default_label") }
    end
  end
end
