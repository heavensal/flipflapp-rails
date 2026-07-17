require "rails_helper"

RSpec.describe "Events", type: :request do
  describe "GET /events/:id" do
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
