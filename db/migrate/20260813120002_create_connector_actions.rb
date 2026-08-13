class CreateConnectorActions < ActiveRecord::Migration[8.1]
  def change
    create_table :connector_actions do |t|
      t.references :connector, null: false, foreign_key: true
      t.string  :name, null: false
      t.text    :description
      t.integer :kind, null: false
      t.jsonb   :input_schema, null: false, default: {}
      t.jsonb   :definition, null: false, default: {}
      t.timestamps
    end

    add_index :connector_actions, [ :connector_id, :name ], unique: true
  end
end
