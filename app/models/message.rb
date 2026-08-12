class Message < ApplicationRecord
  acts_as_message chat: :session, chat_class: "Session",
                   model: :llm_model, model_class: "Llm::Model",
                   tool_calls: :llm_tool_calls, tool_call_class: "Llm::ToolCall"

  broadcasts_to ->(message) { "session_#{message.session_id}" }, inserts_by: :append

  enum :role, { system: 0, user: 1, assistant: 2, tool: 3 }
end
