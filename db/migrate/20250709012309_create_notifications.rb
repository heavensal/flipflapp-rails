class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notif_type, null: false
      t.text :message, null: false
      t.boolean :read, null: false, default: false
      t.string :redirect_url

      t.timestamps
    end
  end
end
