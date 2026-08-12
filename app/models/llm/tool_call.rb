class Llm::ToolCall < ApplicationRecord
  self.table_name = "llm_tool_calls"

  acts_as_tool_call message: :message, message_class: "Message",
                     result: :result, result_class: "Message"
end
