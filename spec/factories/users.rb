require "securerandom"

FactoryBot.define do
  factory :user do
    # SecureRandom avoids collisions when the test DB could not be purged (Neon pooler).
    sequence(:email) { |n| "user#{n}.#{SecureRandom.hex(4)}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :admin do
      role { "admin" }
    end
  end
end
