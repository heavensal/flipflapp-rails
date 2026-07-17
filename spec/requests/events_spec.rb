require "rails_helper"

RSpec.describe "Events", type: :request do
  describe "GET /events" do
    it "lists private events from the current user and accepted friends" do
      viewer = create(:user)
      friend = create(:user)
      stranger = create(:user)
      create(:friendship, sender: viewer, receiver: friend, status: "accepted")

      own_private = create(:event, user: viewer, is_private: true, title: "Mon privé")
      friend_private = create(:event, user: friend, is_private: true, title: "Privé ami")
      create(:event, user: stranger, is_private: true, title: "Privé inconnu")

      sign_in viewer
      get events_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(own_private.title)
      expect(response.body).to include(friend_private.title)
      expect(response.body).not_to include("Privé inconnu")
    end
  end

  describe "GET /events/:id" do
    it "allows an accepted friend to open a private event" do
      event = create(:event, is_private: true)
      friend = create(:user)
      create(:friendship, sender: event.user, receiver: friend, status: "accepted")

      sign_in friend
      get event_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(event.title)
    end

    it "redirects strangers away from a private event" do
      event = create(:event, is_private: true)
      stranger = create(:user)

      sign_in stranger
      get event_path(event)

      expect(response).to redirect_to(authenticated_root_path)
    end
  end

  describe "POST /events" do
    it "persists latitude and longitude from strong params" do
      user = create(:user)
      sign_in user

      expect {
        post events_path, params: {
          event: {
            title: "Match GPS",
            description: "Avec coords",
            location: "Paris",
            start_time: 2.days.from_now,
            number_of_participants: 10,
            price: 5,
            is_private: true,
            latitude: 48.856613,
            longitude: 2.352222
          }
        }
      }.to change(Event, :count).by(1)

      event = Event.order(:created_at).last
      expect(event.latitude).to eq(BigDecimal("48.856613"))
      expect(event.longitude).to eq(BigDecimal("2.352222"))
      expect(response).to redirect_to(event_path(event))
    end
  end

  describe "PATCH /events/:id" do
    it "updates latitude and longitude from strong params" do
      user = create(:user)
      event = create(:event, user: user, latitude: 48.0, longitude: 2.0)
      sign_in user

      patch event_path(event), params: {
        event: {
          title: event.title,
          location: event.location,
          start_time: event.start_time,
          number_of_participants: event.number_of_participants,
          price: event.price,
          is_private: event.is_private,
          latitude: 45.764043,
          longitude: 4.835659
        }
      }

      expect(response).to redirect_to(event_path(event))
      event.reload
      expect(event.latitude).to eq(BigDecimal("45.764043"))
      expect(event.longitude).to eq(BigDecimal("4.835659"))
    end
  end
end
