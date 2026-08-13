class Api::V1::AgentsController < Api::V1::BaseController
  def index
    render json: current_account.agents.available
  end

  def show
    render json: current_account.agents.available.find(params[:id])
  end
end
