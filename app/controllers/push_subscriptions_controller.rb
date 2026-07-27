# frozen_string_literal: true

class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    subscription = current_user.push_subscriptions.find_or_initialize_by(endpoint: subscription_params[:endpoint])
    subscription.assign_attributes(subscription_params.slice(:p256dh, :auth))

    if subscription.save
      head :ok
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    subscription = current_user.push_subscriptions.find_by(endpoint: subscription_params[:endpoint])
    subscription&.destroy!
    head :no_content
  end

  private

  def subscription_params
    params.require(:push_subscription).permit(:endpoint, :p256dh, :auth)
  end
end
