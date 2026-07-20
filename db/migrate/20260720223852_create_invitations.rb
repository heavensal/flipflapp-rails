class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true # invited player
      t.timestamps
    end
    add_index :invitations, [ :event_id, :user_id ], unique: true
  end
end
