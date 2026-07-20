class Friendship < ApplicationRecord
  include Friendship::Notifications

  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :status, presence: true, inclusion: { in: %w[pending accepted declined] }

  validates :sender_id, uniqueness: { scope: :receiver_id }
  validate :cannot_friend_self
  validate :not_already_friends

  def cannot_friend_self
    errors.add(:receiver_id, :self) if sender_id == receiver_id
  end

  def not_already_friends
    if Friendship.exists?(sender_id: receiver_id, receiver_id: sender_id)
      errors.add(:base, :already_exists)
    end
  end


  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :declined, -> { where(status: "declined") }

  def self.accepted_friend_ids_for(user)
    accepted
      .where("sender_id = :id OR receiver_id = :id", id: user.id)
      .select(sanitize_sql_array([
        "CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END",
        user.id
      ]))
  end

  def accept
    return false unless pending?

    update(status: "accepted")
  end

  def decline
    return false unless pending?

    update(status: "declined")
  end
end
