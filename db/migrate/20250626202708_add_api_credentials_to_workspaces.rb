class AddApiCredentialsToWorkspaces < ActiveRecord::Migration[8.0]
  def change
    add_column :workspaces, :api_key, :string
    add_column :workspaces, :api_secret, :string
    add_index :workspaces, :api_key, unique: true
  end
end
