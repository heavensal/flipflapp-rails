class Friendship < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :status, presence: true, inclusion: { in: %w[pending accepted declined] }

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :declined, -> { where(status: "declined") }

  def accept
    update(status: "accepted")
  end

  def decline
    update(status: "declined")
  end
end
