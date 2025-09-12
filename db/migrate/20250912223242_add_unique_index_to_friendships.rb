class AddUniqueIndexToFriendships < ActiveRecord::Migration[8.0]
  def change
    add_index :friendships, [:sender_id, :receiver_id], unique: true
  end
end
