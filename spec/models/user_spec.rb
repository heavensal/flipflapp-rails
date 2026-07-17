require "rails_helper"

RSpec.describe User, type: :model do
  describe "roles" do
    it "identifies admin users" do
      admin = build(:user, role: "admin")
      player = build(:user, role: "player")

      expect(admin).to be_admin
      expect(player).not_to be_admin
    end
  end

  describe "validations" do
    it "requires first_name and last_name" do
      user = build(:user, first_name: nil, last_name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to be_present
      expect(user.errors[:last_name]).to be_present
    end

    it "rejects duplicate usernames regardless of case" do
      create(:user, username: "player123")

      user = build(:user, username: "Player123")

      expect(user).not_to be_valid
      expect(user.errors[:username]).to be_present
    end

    it "requires an allowed role" do
      user = build(:user, role: "owner")

      expect(user).not_to be_valid
      expect(user.errors[:role]).to be_present
    end
  end

  describe "callbacks" do
    it "sets provider and uid before validation" do
      user = build(:user, provider: nil, uid: nil)
      user.valid?

      expect(user.provider).to eq("email")
      expect(user.uid).to eq(user.email)
    end

    it "keeps email uid synchronized for email users" do
      user = create(:user, email: "old@example.com")

      user.email = "new@example.com"
      user.valid?

      expect(user.uid).to eq("new@example.com")
    end

    it "sets a unique username before validation" do
      create(:user, first_name: "Jane", last_name: "Doe", username: "janed#0007")

      user = build(:user, first_name: "Jane", last_name: "Doe", username: nil)
      allow(user).to receive(:rand).with(0..9999).and_return(7, 42)
      user.valid?

      expect(user.username).to eq("janed#0042")
    end
  end

  describe ".ransackable_attributes" do
    it "does not expose email search" do
      expect(described_class.ransackable_attributes).not_to include("email")
    end
  end

  describe ".find_for_confirmation_email" do
    it "finds a user by email without case or surrounding whitespace sensitivity" do
      user = create(:user, email: "player@example.com")

      expect(described_class.find_for_confirmation_email(" Player@Example.com ")).to eq(user)
    end

    it "finds a user by pending reconfirmation email" do
      user = create(:user, unconfirmed_email: "next@example.com")

      expect(described_class.find_for_confirmation_email("next@example.com")).to eq(user)
    end

    it "returns nil when no confirmation email matches" do
      expect(described_class.find_for_confirmation_email("missing@example.com")).to be_nil
    end
  end

  describe ".users_without_friendship" do
    it "excludes users who already have any friendship with the current user" do
      current_user = create(:user)
      friend = create(:user)
      stranger = create(:user)
      create(:friendship, sender: current_user, receiver: friend, status: "declined")

      expect(described_class.users_without_friendship(current_user)).to contain_exactly(stranger)
    end
  end

  describe "friendship helpers" do
    it "finds the friendship with another user regardless of direction" do
      sender = create(:user)
      receiver = create(:user)
      friendship = create(:friendship, sender: sender, receiver: receiver)

      expect(receiver.friendship_with(sender)).to eq(friendship)
    end

    it "detects pending and accepted relationship states" do
      current_user = create(:user)
      other_user = create(:user)
      friendship = create(:friendship, sender: other_user, receiver: current_user, status: "pending")

      expect(current_user.has_pending_request_from?(other_user)).to be(true)
      expect(current_user.has_no_friendship_with?(other_user)).to be(false)

      friendship.accept

      expect(current_user.is_friend_with?(other_user)).to be(true)
    end

    it "detects pending requests sent by the user" do
      current_user = create(:user)
      other_user = create(:user)
      create(:friendship, sender: current_user, receiver: other_user, status: "pending")

      expect(current_user.has_asked_to_be_friend_with?(other_user)).to be(true)
    end

    it "returns false when unsaved users have no friendship" do
      current_user = build(:user)
      other_user = build(:user)

      expect(current_user.has_pending_request_from?(other_user)).to be(false)
      expect(current_user.has_asked_to_be_friend_with?(other_user)).to be(false)
    end

    it "returns accepted friends who are not event participants" do
      current_user = create(:user)
      invited_friend = create(:user)
      participating_friend = create(:user)
      event = create(:event)
      create(:friendship, sender: current_user, receiver: invited_friend, status: "accepted")
      create(:friendship, sender: participating_friend, receiver: current_user, status: "accepted")
      create(:event_participant, event: event, user: participating_friend)

      expect(current_user.get_my_friends_but_not_participants(event)).to contain_exactly(invited_friend)
    end

    it "destroys all sent and received friendships when the user is destroyed" do
      user = create(:user)
      sent_receiver = create(:user)
      received_sender = create(:user)
      create(:friendship, sender: user, receiver: sent_receiver, status: "declined")
      create(:friendship, sender: received_sender, receiver: user, status: "declined")

      expect { user.destroy! }.to change(Friendship, :count).by(-2)
    end
  end

  describe "associations" do
    it "keeps pending friendship associations scoped" do
      user = create(:user)
      pending_receiver = create(:user)
      accepted_receiver = create(:user)
      pending_friendship = create(:friendship, sender: user, receiver: pending_receiver, status: "pending")
      create(:friendship, sender: user, receiver: accepted_receiver, status: "accepted")

      expect(user.pending_sent_friendships).to contain_exactly(pending_friendship)
    end

    it "keeps accepted friendship associations scoped" do
      user = create(:user)
      pending_receiver = create(:user)
      accepted_receiver = create(:user)
      create(:friendship, sender: user, receiver: pending_receiver, status: "pending")
      accepted_friendship = create(:friendship, sender: user, receiver: accepted_receiver, status: "accepted")

      expect(user.accepted_sent_friendships).to contain_exactly(accepted_friendship)
    end
  end

  describe "username generation" do
    it "does not update the record a second time after create" do
      user = create(:user)

      expect(user.username).to be_present
      expect(user.previous_changes).to include("id")
    end
  end
end
