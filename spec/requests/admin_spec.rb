require "rails_helper"

RSpec.describe "Admin", type: :request do
  describe "authorization" do
    it "redirects players away from the admin area" do
      sign_in create(:user)

      get admin_root_path

      expect(response).to redirect_to(authenticated_root_path)
      expect(flash[:alert]).to eq(I18n.t("admin.authorization.forbidden"))
    end

    it "redirects guests to sign in" do
      get admin_root_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /admin" do
    it "lists all admin resources for an admin user" do
      sign_in create(:user, :admin)

      get admin_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.models.events"))
      expect(response.body).to include(I18n.t("admin.models.users"))
    end
  end

  describe "admin users" do
    it "lets an admin update a user role" do
      admin = create(:user, :admin)
      player = create(:user, role: "player")
      sign_in admin

      patch admin_user_path(player), params: { user: { role: "admin" } }

      expect(player.reload).to be_admin
      expect(response).to redirect_to(admin_user_path(player))
    end

    it "does not expose encrypted passwords on the show page" do
      admin = create(:user, :admin)
      player = create(:user)
      sign_in admin

      get admin_user_path(player)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("encrypted_password")
      expect(response.body).not_to include(player.encrypted_password)
    end

    it "sends a password reset email" do
      admin = create(:user, :admin)
      player = create(:user)
      sign_in admin

      expect {
        post send_password_reset_admin_user_path(player)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(response).to redirect_to(admin_user_path(player))
    end

    it "shows all event columns in the nested events table" do
      admin = create(:user, :admin)
      player = create(:user)
      event = create(:event, user: player, title: "Sunday Match", location: "Parc des Sports")
      sign_in admin

      get admin_user_path(player)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("title")
      expect(response.body).to include("location")
      expect(response.body).to include("Sunday Match")
      expect(response.body).to include("Parc des Sports")
      expect(response.body).to include(event.start_time.to_fs(:long))
    end
  end

  describe "admin events" do
    it "shows an event with nested association tables" do
      admin = create(:user, :admin)
      event = create(:event)
      sign_in admin

      get admin_event_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(event.title)
      expect(response.body).to include(I18n.t("admin.associations.event_teams"))
      expect(response.body).to include(I18n.t("admin.associations.event_participants"))
      expect(response.body).to include(I18n.t("admin.actions.player_view"))
    end

    it "lets an admin destroy an event they do not own" do
      admin = create(:user, :admin)
      event = create(:event)
      sign_in admin

      expect {
        delete admin_event_path(event)
      }.to change(Event, :count).by(-1)

      expect(response).to redirect_to(admin_events_path)
    end
  end
end
