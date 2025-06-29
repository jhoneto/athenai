class AgentFunctionsController < BaseController
  before_action :set_workspace
  before_action :set_agent
  before_action :set_agent_function, only: [ :destroy ]

  def index
    @agent_functions = @agent.agent_functions.includes(:function)
    @available_functions = @workspace.functions - @agent.functions
  end

  def create
    @agent_function = @agent.agent_functions.build(agent_function_params)

    if @agent_function.save
      redirect_to workspace_agent_agent_functions_path(@workspace, @agent), notice: "Function was successfully associated."
    else
      redirect_to workspace_agent_agent_functions_path(@workspace, @agent), alert: "Error associating function."
    end
  end

  def destroy
    @agent_function.destroy
    redirect_to workspace_agent_agent_functions_path(@workspace, @agent), notice: "Function association was removed."
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def set_agent
    @agent = @workspace.agents.find(params[:agent_id])
  end

  def set_agent_function
    @agent_function = @agent.agent_functions.find(params[:id])
  end

  def agent_function_params
    params.require(:agent_function).permit(:function_id)
  end
end
