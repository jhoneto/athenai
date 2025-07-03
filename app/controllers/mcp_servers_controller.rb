class McpServersController < BaseController
  before_action :set_workspace
  before_action :set_mcp_server, only: [ :show, :edit, :update, :destroy ]

  def index
    @mcp_servers = @workspace.mcp_servers.order(:name)
  end

  def show
  end

  def new
    @mcp_server = @workspace.mcp_servers.build
  end

  def create
    @mcp_server = @workspace.mcp_servers.build(mcp_server_params)

    if @mcp_server.save
      redirect_to [ @workspace, @mcp_server ], notice: "MCP Server was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @mcp_server.update(mcp_server_params)
      redirect_to [ @workspace, @mcp_server ], notice: "MCP Server was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @mcp_server.destroy
    redirect_to workspace_mcp_servers_url(@workspace), notice: "MCP Server was successfully deleted."
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
    access = workspace_access(@workspace)
    unless access[:owner] || access[:access_functions]
      flash[:alert] = "You don't have permission to access MCP servers in this workspace."
      redirect_to root_path and return
    end
  end

  def set_mcp_server
    @mcp_server = @workspace.mcp_servers.find(params[:id])
  end

  def mcp_server_params
    params.require(:mcp_server).permit(:name, :description, :url, :enabled, :headers)
  end
end
