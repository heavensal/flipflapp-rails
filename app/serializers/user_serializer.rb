# frozen_string_literal: true

class UserSerializer
  include Alba::Resource

  attributes :id, :first_name, :last_name, :username

  attribute :avatar_url do |user|
    user.avatar.url.presence
  end
end
