class AgentsController < ApplicationController
  before_action :set_agent, only: %i[show edit update destroy publish]

  def index
    @agents = current_account.agents.order(:name)
  end

  def show; end

  def new
    @agent = current_account.agents.new
    @llm_profiles = Llm::ProfileCatalog.new(current_account).selectable_profiles
  end

  def create
    @agent = current_account.agents.new(agent_params)
    @agent.save ? redirect_to(@agent) : render(:new, status: :unprocessable_entity)
  end

  def edit
    @llm_profiles = Llm::ProfileCatalog.new(current_account).selectable_profiles
  end

  def update
    @agent.update(agent_params) ? redirect_to(@agent) : render(:edit, status: :unprocessable_entity)
  end

  def publish
    @agent.publish!
    redirect_to @agent
  rescue ActiveRecord::RecordInvalid
    redirect_to @agent, alert: t("agents.show.publish_incomplete")
  end

  def destroy
    @agent.destroy
    redirect_to agents_path
  end

  private

  def set_agent
    @agent = current_account.agents.find(params[:id])
  end

  def agent_params
    params.require(:agent).permit(:name, :description, :system_prompt, :llm_profile_id, :temperature)
  end
end
