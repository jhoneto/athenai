class CreateLlms < ActiveRecord::Migration[8.0]
  def change
    create_table :llms do |t|
      t.string :name
      t.string :provider
      t.string :model
      t.text :configs
      t.references :workspace, null: false, foreign_key: true

      t.timestamps
    end
  end
end
