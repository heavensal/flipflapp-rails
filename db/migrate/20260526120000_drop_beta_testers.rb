class DropBetaTesters < ActiveRecord::Migration[8.0]
  def up
    drop_table :beta_testers, if_exists: true
  end

  def down
    create_table :beta_testers do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :favorite_social_network
      t.string :social_network_name
      t.integer :age

      t.timestamps
    end
  end
end
