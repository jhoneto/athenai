class Api::BaseController < ApplicationController
  before_action :authenticate_api_key

  private

  def authenticate_api_key
    api_key = params[:api_key]
    api_secret = request.headers["X-API-Secret"]

    if api_key.blank? || api_secret.blank?
      render json: { error: "API key and secret are required" }, status: :unauthorized
      return
    end

    @workspace = Workspace.find_by(api_key: api_key, api_secret: api_secret)

    unless @workspace
      render json: { error: "Invalid API credentials" }, status: :unauthorized
      nil
    end
  end

  def current_workspace
    @workspace
  end
end
