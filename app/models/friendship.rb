class Friendship < ApplicationRecord
  include Friendship::Notifications

  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :status, presence: true, inclusion: { in: %w[pending accepted declined] }

  validates :sender_id, uniqueness: { scope: :receiver_id, message: "Demande d'amitié déjà envoyée." }
  validate :cannot_friend_self
  validate :not_already_friends

  def cannot_friend_self
    errors.add(:receiver_id, "Vous ne pouvez pas vous envoyer une demande d'amitié à vous-même.") if sender_id == receiver_id
  end

  def not_already_friends
    if Friendship.exists?(sender_id: receiver_id, receiver_id: sender_id)
      errors.add(:base, "Une demande d'amitié existe déjà entre ces utilisateurs.")
    end
  end


  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  def self.accepted_friend_ids_for(user)
    accepted
      .where("sender_id = :id OR receiver_id = :id", id: user.id)
      .select(sanitize_sql_array([
        "CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END",
        user.id
      ]))
  end

  def accept
    update(status: "accepted")
  end

  def decline
    update(status: "declined")
  end
end
