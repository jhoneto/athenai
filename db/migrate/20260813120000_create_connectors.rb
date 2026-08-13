class CreateConnectors < ActiveRecord::Migration[8.1]
  def change
    create_table :connectors do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :kind, null: false
      t.string  :name, null: false
      t.text    :description
      t.jsonb   :config, null: false, default: {}
      t.integer :status, null: false, default: 0
      t.timestamps
    end

    add_index :connectors, [ :account_id, :name ], unique: true
  end
end
