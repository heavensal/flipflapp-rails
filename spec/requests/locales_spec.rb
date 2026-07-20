# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locales", type: :request do
  describe "PATCH /locale/:locale" do
    it "stores a permanent locale cookie and redirects back" do
      get unauthenticated_root_path

      patch locale_path(locale: :en), headers: { "HTTP_REFERER" => unauthenticated_root_path }

      expect(response).to redirect_to(unauthenticated_root_path)
      expect(cookies[:locale]).to eq("en")
      follow_redirect!
      expect(response.body).to include("Ready to play?")
    end

    it "rejects an unsupported locale" do
      patch locale_path(locale: :es), headers: { "HTTP_REFERER" => unauthenticated_root_path }

      expect(response).to redirect_to(unauthenticated_root_path)
      expect(cookies[:locale]).to be_blank
    end

    it "uses the Accept-Language header when no cookie is set" do
      get unauthenticated_root_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.9" }

      expect(response.body).to include("Ready to play?")
    end
  end
end
