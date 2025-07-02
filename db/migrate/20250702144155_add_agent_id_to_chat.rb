class AddAgentIdToChat < ActiveRecord::Migration[8.0]
  def change
    add_reference :chats, :agent, null: false, foreign_key: true, index: true
  end
end
