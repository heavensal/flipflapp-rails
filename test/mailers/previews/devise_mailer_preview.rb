class DeviseMailerPreview < ActionMailer::Preview
  # http://localhost:3000/rails/mailers/devise_mailer/confirmation_instructions
  def confirmation_instructions
    user = User.first || User.new(first_name: "Adam", email: "test@flipflapp.fr")
    token = "fake_token_123"

    Devise::Mailer.confirmation_instructions(user, token)
  end

  def email_changed
    user = User.first || User.new(first_name: "Adam", email: "test@flipflapp.fr")
    Devise::Mailer.email_changed(user)
  end

  def password_change
    user = User.first || User.new(first_name: "Adam", email: "test@flipflapp.fr")
    Devise::Mailer.password_change(user)
  end

  def reset_password_instructions
    user = User.first || User.new(first_name: "Adam", email: "test@flipflapp.fr")
    token = "fake_token_123"
    Devise::Mailer.reset_password_instructions(user, token)
  end

  def unlock_instructions
    user = User.first || User.new(first_name: "Adam", email: "test@flipflapp.fr")
    token = "fake_token_123"
    Devise::Mailer.unlock_instructions(user, token)
  end
end
