class LlmsController < ApplicationController
  before_action :set_workspace
  before_action :set_llm, only: [:show, :edit, :update, :destroy]

  def index
    @llms = @workspace.llms
  end

  def show
  end

  def new
    @llm = @workspace.llms.build
  end

  def create
    @llm = @workspace.llms.build(llm_params)
    
    if @llm.save
      redirect_to [@workspace, @llm], notice: 'LLM was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @llm.update(llm_params)
      redirect_to [@workspace, @llm], notice: 'LLM was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @llm.destroy
    redirect_to workspace_llms_url(@workspace), notice: 'LLM was successfully deleted.'
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def set_llm
    @llm = @workspace.llms.find(params[:id])
  end

  def llm_params
    params.require(:llm).permit(:name, :provider, :model, :configs)
  end
end