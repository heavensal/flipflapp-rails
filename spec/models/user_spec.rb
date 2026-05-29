require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires first_name and last_name" do
      user = build(:user, first_name: nil, last_name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to be_present
      expect(user.errors[:last_name]).to be_present
    end
  end

  describe "callbacks" do
    it "sets provider and uid before create" do
      user = build(:user, provider: nil, uid: nil)
      user.save!
      expect(user.provider).to eq("email")
      expect(user.uid).to eq(user.email)
    end

    it "sets a unique username after create" do
      user = create(:user)
      expect(user.username).to be_present
    end
  end
end
