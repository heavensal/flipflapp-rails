# frozen_string_literal: true

FactoryBot.define do
  factory :push_subscription do
    association :user
    sequence(:endpoint) { |n| "https://fcm.googleapis.com/fcm/send/subscription-#{n}" }
    p256dh { "BNcRd" + SecureRandom.hex(20) }
    auth { SecureRandom.hex(8) }
  end
end
