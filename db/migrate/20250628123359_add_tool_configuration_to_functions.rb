class AddToolConfigurationToFunctions < ActiveRecord::Migration[8.0]
  def change
    add_column :functions, :description, :text
    add_column :functions, :parameters, :jsonb, default: {}
    add_column :functions, :return_type, :string
    add_column :functions, :enabled, :boolean, default: true
    add_column :functions, :tool_type, :string, default: 'custom'

    add_index :functions, :enabled
    add_index :functions, :tool_type
    add_index :functions, :parameters, using: :gin
  end
end
