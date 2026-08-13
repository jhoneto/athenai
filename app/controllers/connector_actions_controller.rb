class ConnectorActionsController < ApplicationController
  include ConnectorFeatureGuard

  before_action :set_connector
  before_action :set_action, only: %i[destroy test]

  def index
    @actions = @connector.actions.order(:name)
  end

  def new
    @action = @connector.actions.new
  end

  def create
    @action = @connector.actions.new(action_params)
    @action.save ? redirect_to(connector_actions_path(@connector)) : render(:new, status: :unprocessable_entity)
  end

  def destroy
    @action.destroy
    redirect_to connector_actions_path(@connector)
  end

  def import
    Connector::ImportOpenApiJob.perform_later(@connector.id)
    redirect_to connector_actions_path(@connector), notice: t(".importing")
  end

  def test
    result = @connector.adapter.call(@action, JSON.parse(params[:params].presence || "{}"))
    redirect_to connector_actions_path(@connector), notice: result.to_s.truncate(500)
  rescue Connector::Adapters::Base::ExecutionError => e
    redirect_to connector_actions_path(@connector), alert: e.message
  end

  private

  def set_connector
    @connector = current_account.connectors.find(params[:connector_id])
  end

  def set_action
    @action = @connector.actions.find(params[:id])
  end

  def action_params
    params.require(:connector_action).permit(:name, :description, :kind, :input_schema, :definition).tap do |attrs|
      attrs[:input_schema] = JSON.parse(attrs[:input_schema]) if attrs[:input_schema].present?
      attrs[:definition] = JSON.parse(attrs[:definition]) if attrs[:definition].present?
    end
  end
end
