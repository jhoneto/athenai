class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_key!

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "not_found" }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    render json: { errors: exception.record.errors }, status: :unprocessable_entity
  end

  private

  def authenticate_api_key!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    @api_key = ApiKey.authenticate(token)

    render json: { error: "unauthorized" }, status: :unauthorized and return unless @api_key
    @api_key.touch(:last_used_at)
  end

  def current_account
    @api_key.account
  end
end
