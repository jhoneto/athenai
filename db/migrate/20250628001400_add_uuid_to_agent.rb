class AddUuidToAgent < ActiveRecord::Migration[8.0]
  def change
    add_column :agents, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_index :agents, :uuid, unique: true
  end
end
