class RemoveWorkspaceFromChats < ActiveRecord::Migration[8.0]
  def change
    remove_column :chats, :workspace_id, :integer
  end
end
