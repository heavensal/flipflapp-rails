# frozen_string_literal: true

class FriendshipSerializer
  include Alba::Resource

  attributes :id, :sender_id, :receiver_id, :status, :created_at, :updated_at

  attribute :sender do |friendship|
    UserSerializer.new(friendship.sender).serializable_hash
  end

  attribute :receiver do |friendship|
    UserSerializer.new(friendship.receiver).serializable_hash
  end
end
