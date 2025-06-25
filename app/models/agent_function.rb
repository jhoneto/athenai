class AgentFunction < ApplicationRecord
  belongs_to :agent
  belongs_to :function

  validates :agent_id, uniqueness: { scope: :function_id }
end