class AgentMcpServersController < BaseController
  before_action :set_workspace
  before_action :set_agent
  before_action :set_agent_mcp_server, only: [ :destroy ]

  def index
    @agent_mcp_servers = @agent.agent_mcp_servers.includes(:mcp_server)
    @available_mcp_servers = @workspace.mcp_servers.enabled - @agent.mcp_servers
  end

  def create
    @agent_mcp_server = @agent.agent_mcp_servers.build(agent_mcp_server_params)

    if @agent_mcp_server.save
      redirect_to workspace_agent_agent_mcp_servers_path(@workspace, @agent), notice: "MCP Server was successfully associated."
    else
      redirect_to workspace_agent_agent_mcp_servers_path(@workspace, @agent), alert: "Error associating MCP Server."
    end
  end

  def destroy
    @agent_mcp_server.destroy
    redirect_to workspace_agent_agent_mcp_servers_path(@workspace, @agent), notice: "MCP Server association was removed."
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
    access = workspace_access(@workspace)
    unless access[:owner] || access[:access_agents]
      flash[:alert] = "You don't have permission to access agents in this workspace."
      redirect_to root_path and return
    end
  end

  def set_agent
    @agent = @workspace.agents.find(params[:agent_id])
  end

  def set_agent_mcp_server
    @agent_mcp_server = @agent.agent_mcp_servers.find(params[:id])
  end

  def agent_mcp_server_params
    params.require(:agent_mcp_server).permit(:mcp_server_id)
  end
end
