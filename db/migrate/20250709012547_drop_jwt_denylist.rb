class DropJwtDenylist < ActiveRecord::Migration[8.0]
  def change
    drop_table :jwt_denylist, if_exists: true do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false

      t.index :jti, unique: true
    end
  end
end
