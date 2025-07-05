class AgentMcpServer < ApplicationRecord
  belongs_to :agent
  belongs_to :mcp_server

  validates :agent_id, uniqueness: { scope: :mcp_server_id }
end
