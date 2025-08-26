class EventParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :event_team

  validates :user_id, uniqueness: { scope: [ :event_id ], message: "est déjà inscrit à cet événement" }
end
