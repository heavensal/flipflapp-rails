class UpdateNotifications < ActiveRecord::Migration[8.0]
  def change
    change_table :notifications do |t|
      t.references :notifiable, polymorphic: true
      t.integer :kind, null: false, default: 0
      t.jsonb :payload, default: {}
      t.remove :notif_type
      t.remove :message
      t.remove :redirect_url
    end

    add_index :notifications, [ :user_id, :read ]
    add_index :notifications, [:user_id, :notifiable_type, :notifiable_id]

  end
end
