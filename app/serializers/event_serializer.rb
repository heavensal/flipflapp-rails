# frozen_string_literal: true

class EventSerializer
  include Alba::Resource

  attributes :id, :title, :description, :location, :start_time,
             :number_of_participants, :price, :is_private,
             :latitude, :longitude, :user_id, :created_at, :updated_at

  attribute :participants_count, &:participants_count
  attribute :spots_remaining, &:spots_remaining
  attribute :fill_level, &:fill_level

  attribute :user do |event|
    UserSerializer.new(event.user).serializable_hash
  end

  attribute :current_user do |event|
    viewer = params[:current_user]
    next nil if viewer.blank?

    {
      participant: event.in_this_event?(viewer),
      can_invite: event.can_invite?(viewer),
      author: event.am_i_the_author?(viewer),
      invited: event.invited?(viewer)
    }
  end
end
