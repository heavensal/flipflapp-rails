# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  # def new
  #   super
  # end

  # POST /resource/confirmation
  def create
    return render_confirmation_error(:invalid) unless valid_confirmation_email?
    return render_confirmation_error(:not_found) unless confirmation_email_exists?

    self.resource = resource_class.send_confirmation_instructions(confirmation_resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_resending_confirmation_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  # def show
  #   super
  # end

  private

  def confirmation_email
    resource_params[:email].to_s.strip
  end

  def valid_confirmation_email?
    confirmation_email.match?(Devise.email_regexp)
  end

  def confirmation_email_exists?
    resource_class.find_for_confirmation_email(confirmation_email).present?
  end

  def confirmation_resource_params
    resource_params.merge(email: confirmation_email)
  end

  def render_confirmation_error(error)
    self.resource = resource_class.new(email: confirmation_email)
    resource.errors.add(:email, error)

    respond_with_navigational(resource) { render :new, status: :unprocessable_entity }
  end

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # def after_confirmation_path_for(resource_name, resource)
  #   super(resource_name, resource)
  # end
end
