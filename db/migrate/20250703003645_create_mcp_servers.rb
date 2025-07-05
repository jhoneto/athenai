class CreateMcpServers < ActiveRecord::Migration[8.0]
  def change
    create_table :mcp_servers do |t|
      t.string :name, null: false
      t.text :description
      t.string :url, null: false
      t.jsonb :headers, default: {}
      t.boolean :enabled, default: true
      t.references :workspace, null: false, foreign_key: true

      t.timestamps
    end

    add_index :mcp_servers, :enabled
    add_index :mcp_servers, :headers, using: :gin
  end
end
