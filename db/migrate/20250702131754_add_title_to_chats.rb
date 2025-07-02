class AddTitleToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :title, :string, null: false, default: 'Nova Conversa'
  end
end
