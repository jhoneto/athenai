class ToolCall < ApplicationRecord
  acts_as_tool_call # Assumes Message model name

  belongs_to :message
end
