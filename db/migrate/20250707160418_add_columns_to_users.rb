class AddColumnsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :username, :string
    add_column :users, :avatar, :string
    add_column :users, :role, :string, default: "player"
    add_column :users, :status, :string, default: "private"
    add_index :users, :username, unique: true
  end
end
