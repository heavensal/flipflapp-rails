class EventTeam < ApplicationRecord
  belongs_to :event
  has_many :event_participants, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :event_id, case_sensitive: false, message: "une équipe porte déjà le même nom" }

  def in_this_team?(user)
    event_participants.exists?(user: user)
  end
end
