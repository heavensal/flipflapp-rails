# frozen_string_literal: true

class CurrentUserSerializer
  include Alba::Resource

  attributes :id, :email, :first_name, :last_name, :username, :role

  attribute :avatar_url do |user|
    user.avatar.url.presence
  end
end
