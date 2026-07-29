class ApplicationController < ActionController::Base
  include SubscriptionGuard

  allow_browser versions: :modern
  stale_when_importmap_changes

  layout :devise_layout

  before_action :authenticate_user!
  before_action :set_current_account

  private

  def set_current_account
    @current_account = current_user&.accounts&.first
  end

  def current_account
    @current_account
  end
  helper_method :current_account

  def after_sign_in_path_for(_resource)
    billing_path
  end

  def after_sign_up_path_for(_resource)
    billing_path
  end

  def devise_layout
    devise_controller? ? "auth" : "application"
  end
end
