class CreateAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :agents do |t|
      t.string :name
      t.text :prompt
      t.references :workspace, null: false, foreign_key: true
      t.references :llm, null: false, foreign_key: true

      t.timestamps
    end
  end
end
