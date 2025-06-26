class CreateAgentFunctions < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_functions do |t|
      t.references :agent, null: false, foreign_key: true
      t.references :function, null: false, foreign_key: true

      t.timestamps
    end

    add_index :agent_functions, [ :agent_id, :function_id ], unique: true
  end
end
