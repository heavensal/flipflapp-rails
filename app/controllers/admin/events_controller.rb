module Admin
  class EventsController < BaseController
    include Resourceful
    admin_resource :events
  end
end
