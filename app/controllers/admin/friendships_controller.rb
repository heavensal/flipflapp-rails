module Admin
  class FriendshipsController < BaseController
    include Resourceful
    admin_resource :friendships
  end
end
