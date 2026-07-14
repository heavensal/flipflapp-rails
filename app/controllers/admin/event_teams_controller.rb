module Admin
  class EventTeamsController < BaseController
    include Resourceful
    admin_resource :event_teams
  end
end
