# frozen_string_literal: true

class DeviceToken < ApplicationRecord
  PLATFORMS = %w[android ios].freeze

  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :platform, presence: true, inclusion: { in: PLATFORMS }

  def self.register_for(user, token:, platform:)
    device_token = find_or_initialize_by(token: token)
    device_token.user = user
    device_token.platform = platform
    device_token
  end
end
