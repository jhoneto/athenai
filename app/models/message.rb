class Message < ApplicationRecord
  acts_as_message # Assumes Chat and ToolCall model names

  belongs_to :chat
  belongs_to :tool_call
end
