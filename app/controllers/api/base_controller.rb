class Api::BaseController < ActionController::API
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity_response
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response
  rescue_from StandardError, with: :render_generic_error_response

  before_action :authenticate_api_key

  private

  def authenticate_api_key
    api_key = params[:workspace_api_key]
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

  def render_unprocessable_entity_response(exception)
    render json: exception.record.errors, status: :unprocessable_entity
  end

  def render_not_found_response(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def render_generic_error_response(exception)
    Rails.logger.debug exception.backtrace
    render json: { error: exception.message }, status: :internal_server_error
  end
end
