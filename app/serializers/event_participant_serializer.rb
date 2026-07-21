# frozen_string_literal: true

class EventParticipantSerializer
  include Alba::Resource

  attributes :id, :event_id, :event_team_id, :user_id, :created_at, :updated_at

  attribute :user do |event_participant|
    UserSerializer.new(event_participant.user).serializable_hash
  end
end
