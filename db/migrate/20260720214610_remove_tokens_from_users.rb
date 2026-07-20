class RemoveTokensFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :tokens, :json
  end
end
