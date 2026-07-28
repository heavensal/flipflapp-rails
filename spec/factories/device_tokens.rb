# frozen_string_literal: true

FactoryBot.define do
  factory :device_token do
    association :user
    sequence(:token) { |n| "fcm-token-#{n}-#{SecureRandom.hex(8)}" }
    platform { "android" }
  end
end
