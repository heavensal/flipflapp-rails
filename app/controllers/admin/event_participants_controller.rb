module Admin
  class EventParticipantsController < BaseController
    include Resourceful
    admin_resource :event_participants
  end
end
