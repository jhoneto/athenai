class Api::V1::ConnectorsController < Api::V1::BaseController
  def index
    render json: current_account.connectors
  end

  def create
    connector = current_account.connectors.create!(connector_params)
    Connector::TestConnectionJob.perform_later(connector.id)
    render json: connector, status: :created
  end

  def show
    render json: current_account.connectors.find(params[:id])
  end

  private

  def connector_params
    params.require(:connector).permit(:kind, :name, :description, config: {})
  end
end
