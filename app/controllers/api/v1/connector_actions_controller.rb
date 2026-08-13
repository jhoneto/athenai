class Api::V1::ConnectorActionsController < Api::V1::BaseController
  def index
    render json: connector.actions
  end

  def create
    action = connector.actions.create!(action_params)
    render json: action, status: :created
  end

  private

  def connector
    @connector ||= current_account.connectors.find(params[:connector_id])
  end

  def action_params
    params.require(:connector_action).permit(:name, :description, :kind, input_schema: {}, definition: {})
  end
end
