# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Push subscriptions", type: :request do
  describe "POST /push_subscription" do
    it "creates a subscription for the signed-in user" do
      user = create(:user)
      sign_in user

      expect {
        post push_subscription_path,
             params: {
               push_subscription: {
                 endpoint: "https://fcm.googleapis.com/fcm/send/abc",
                 p256dh: "key",
                 auth: "secret"
               }
             },
             as: :json
      }.to change(user.push_subscriptions, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "updates keys when the endpoint already exists" do
      user = create(:user)
      subscription = create(:push_subscription, user: user, p256dh: "old", auth: "old")
      sign_in user

      post push_subscription_path,
           params: {
             push_subscription: {
               endpoint: subscription.endpoint,
               p256dh: "new-key",
               auth: "new-auth"
             }
           },
           as: :json

      expect(response).to have_http_status(:ok)
      expect(subscription.reload.p256dh).to eq("new-key")
      expect(subscription.auth).to eq("new-auth")
    end

    it "requires authentication" do
      post push_subscription_path,
           params: {
             push_subscription: {
               endpoint: "https://example.com/push",
               p256dh: "key",
               auth: "secret"
             }
           },
           as: :json

      expect(response).to have_http_status(:unauthorized).or have_http_status(:redirect)
    end
  end

  describe "DELETE /push_subscription" do
    it "destroys the subscription for the current user" do
      user = create(:user)
      subscription = create(:push_subscription, user: user)
      sign_in user

      expect {
        delete push_subscription_path,
               params: { push_subscription: { endpoint: subscription.endpoint } },
               as: :json
      }.to change(user.push_subscriptions, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
