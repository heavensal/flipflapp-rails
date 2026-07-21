# frozen_string_literal: true

class EventTeamSerializer
  include Alba::Resource

  attributes :id, :event_id, :slot, :label, :created_at, :updated_at

  attribute :countable, &:countable?
end
