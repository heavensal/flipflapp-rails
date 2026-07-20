# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invitations", type: :request do
  describe "POST /events/:event_id/invitations" do
    it "creates invitations and notifications for selected friends", :notification_jobs do
      event = create(:event)
      friend = create(:user)
      create(:friendship, sender: event.user, receiver: friend, status: "accepted")
      sign_in event.user

      expect {
        post event_invitations_path(event), params: { user_ids: [ friend.id ] }
      }.to change { event.invitations.where(user: friend).count }.by(1)
        .and change { friend.notifications.invited.count }.by(1)

      expect(response).to redirect_to(event)
      follow_redirect!
      expect(response.body).to include(I18n.t("events.flash.invitations.create.success"))
    end

    it "rejects an empty selection" do
      event = create(:event)
      sign_in event.user

      expect {
        post event_invitations_path(event), params: { user_ids: [] }
      }.not_to change(Invitation, :count)

      expect(response).to redirect_to(event)
      follow_redirect!
      expect(response.body).to include(I18n.t("events.flash.invitations.create.empty"))
    end

    it "rejects invites from users who are not participants" do
      event = create(:event)
      stranger = create(:user)
      friend = create(:user)
      create(:friendship, sender: stranger, receiver: friend, status: "accepted")
      sign_in stranger

      expect {
        post event_invitations_path(event), params: { user_ids: [ friend.id ] }
      }.not_to change(Invitation, :count)

      expect(response).to redirect_to(authenticated_root_path)
    end

    it "ignores user ids that are not inviteable friends" do
      event = create(:event)
      outsider = create(:user)
      sign_in event.user

      expect {
        post event_invitations_path(event), params: { user_ids: [ outsider.id ] }
      }.not_to change(Invitation, :count)

      expect(response).to redirect_to(event)
      follow_redirect!
      expect(response.body).to include(I18n.t("events.flash.invitations.create.empty"))
    end
  end
end
