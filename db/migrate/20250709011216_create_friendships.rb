class CreateFriendships < ActiveRecord::Migration[8.0]
  def change
    create_table :friendships do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :receiver, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: 'pending'
      t.timestamps
    end
  end
end
