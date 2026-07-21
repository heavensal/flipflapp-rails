# frozen_string_literal: true

class NotificationSerializer
  include Alba::Resource

  attributes :id, :user_id, :kind, :read, :payload,
             :notifiable_type, :notifiable_id, :created_at, :updated_at
end
