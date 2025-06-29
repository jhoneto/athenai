class AgentsController < BaseController
  before_action :set_workspace
  before_action :set_agent, only: [ :show, :edit, :update, :destroy ]

  def index
    @agents = @workspace.agents.includes(:llm)
  end

  def show
  end

  def new
    @agent = @workspace.agents.build
    @llms = @workspace.llms
  end

  def create
    @agent = @workspace.agents.build(agent_params)

    if @agent.save
      redirect_to [ @workspace, @agent ], notice: "Agent was successfully created."
    else
      @llms = @workspace.llms
      render :new
    end
  end

  def edit
    @llms = @workspace.llms
  end

  def update
    if @agent.update(agent_params)
      redirect_to [ @workspace, @agent ], notice: "Agent was successfully updated."
    else
      @llms = @workspace.llms
      render :edit
    end
  end

  def destroy
    @agent.destroy
    redirect_to workspace_agents_url(@workspace), notice: "Agent was successfully deleted."
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def set_agent
    @agent = @workspace.agents.find(params[:id])
  end

  def agent_params
    params.require(:agent).permit(:name, :prompt, :llm_id)
  end
end
