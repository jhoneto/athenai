class CreateLlmToolCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_tool_calls do |t|
      t.references :message, null: false, foreign_key: true
      t.string :tool_call_id, null: false
      t.string :name, null: false
      t.text   :thought_signature
      t.jsonb  :arguments, default: {}
      t.timestamps

      t.index :tool_call_id, unique: true
      t.index :name
    end
  end
end
