class CreateBetaTesters < ActiveRecord::Migration[8.0]
  def change
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
