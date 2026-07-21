# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 Events", type: :request do
  describe "GET /api/v1/events" do
    it "lists visible upcoming events" do
      user = create(:user)
      visible = create(:event, user: user, is_private: false)
      create(:event, is_private: true)

      api_get "/api/v1/events", user: user

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |e| e["id"] }
      expect(ids).to include(visible.id)
    end
  end

  describe "GET /api/v1/events/:id" do
    it "returns 404 for a private event the user cannot view" do
      event = create(:event, is_private: true)
      stranger = create(:user)

      api_get "/api/v1/events/#{event.id}", user: stranger

      expect(response).to have_http_status(:not_found)
    end

    it "returns the event with current_user context for the author" do
      user = create(:user)
      event = create(:event, user: user)

      api_get "/api/v1/events/#{event.id}", user: user

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(event.id)
      expect(body["current_user"]).to include("author" => true, "participant" => true)
    end
  end

  describe "POST /api/v1/events" do
    it "creates an event" do
      user = create(:user)

      expect {
        api_post "/api/v1/events", user: user, params: {
          event: {
            title: "API Match",
            description: "From API",
            location: "Lyon",
            start_time: 3.days.from_now,
            number_of_participants: 10,
            price: 5,
            is_private: true,
            latitude: 45.764043,
            longitude: 4.835659
          }
        }
      }.to change(Event, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["title"]).to eq("API Match")
    end
  end

  describe "PATCH /api/v1/events/:id" do
    it "forbids non-authors who can view the event" do
      organizer = create(:user)
      friend = create(:user)
      create(:friendship, sender: organizer, receiver: friend, status: "accepted")
      event = create(:event, user: organizer, is_private: true)

      api_patch "/api/v1/events/#{event.id}", user: friend, params: { event: { title: "Nope" } }

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for strangers on a private event" do
      event = create(:event, is_private: true)
      stranger = create(:user)

      api_patch "/api/v1/events/#{event.id}", user: stranger, params: { event: { title: "Nope" } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/events/:id" do
    it "destroys as author" do
      user = create(:user)
      event = create(:event, user: user)

      expect {
        api_delete "/api/v1/events/#{event.id}", user: user
      }.to change(Event, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
