# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitation, type: :model do
  describe "validations" do
    it "rejects a duplicate invitation for the same user on the same event" do
      event = create(:event)
      user = create(:user)
      create(:invitation, event: event, user: user)

      duplicate = build(:invitation, event: event, user: user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "allows the same user to be invited to different events" do
      user = create(:user)
      create(:invitation, event: create(:event), user: user)

      expect(build(:invitation, event: create(:event), user: user)).to be_valid
    end
  end
end
