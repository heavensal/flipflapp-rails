# frozen_string_literal: true

class InvitationSerializer
  include Alba::Resource

  attributes :id, :event_id, :user_id, :created_at, :updated_at

  attribute :user do |invitation|
    UserSerializer.new(invitation.user).serializable_hash
  end
end
