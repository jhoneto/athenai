class AddUserIdToWorkspaces < ActiveRecord::Migration[8.0]
  def change
    add_reference :workspaces, :user, null: true, foreign_key: true

    # Se houver workspaces existentes, atribuir ao primeiro usuário
    if Workspace.exists? && User.exists?
      first_user = User.first
      Workspace.where(user_id: nil).update_all(user_id: first_user.id)
    end

    change_column_null :workspaces, :user_id, false
  end
end
