class ConnectorsController < ApplicationController
  include ConnectorFeatureGuard

  before_action :set_connector, only: %i[show destroy test]

  def index
    @connectors = current_account.connectors.order(:name)
  end

  def new
    @connector = current_account.connectors.new
  end

  def create
    @connector = current_account.connectors.new(connector_params)
    if @connector.save
      Connector::TestConnectionJob.perform_later(@connector.id)
      redirect_to @connector
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def test
    Connector::TestConnectionJob.perform_later(@connector.id)
    redirect_to @connector, notice: t(".testing")
  end

  def destroy
    @connector.destroy
    redirect_to connectors_path
  end

  private

  def set_connector
    @connector = current_account.connectors.find(params[:id])
  end

  def connector_params
    params.require(:connector).permit(:kind, :name, :description, config: {})
  end
end
