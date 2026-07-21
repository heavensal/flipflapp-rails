class AddUniqueIndexToEventParticipants < ActiveRecord::Migration[8.0]
  def change
    add_index :event_participants,
      [ :event_id, :user_id ],
      unique: true,
      name: "index_event_participants_on_event_and_user"
  end
end
