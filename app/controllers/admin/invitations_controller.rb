# frozen_string_literal: true

module Admin
  class InvitationsController < BaseController
    include Resourceful
    admin_resource :invitations
  end
end
