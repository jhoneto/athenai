class AddLlmToolCallToMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :messages, :llm_tool_call, foreign_key: { to_table: :llm_tool_calls }
  end
end
