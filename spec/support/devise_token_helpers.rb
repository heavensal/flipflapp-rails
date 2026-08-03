# frozen_string_literal: true

module DeviseTokenHelpers
  def raw_confirmation_token_for(user)
    raw, encrypted = Devise.token_generator.generate(User, :confirmation_token)
    user.update!(confirmation_token: encrypted, confirmation_sent_at: Time.current)
    raw
  end

  def raw_reset_password_token_for(user)
    raw, encrypted = Devise.token_generator.generate(User, :reset_password_token)
    user.update!(reset_password_token: encrypted, reset_password_sent_at: Time.current)
    raw
  end
end

RSpec.configure do |config|
  config.include DeviseTokenHelpers, type: :request
end
