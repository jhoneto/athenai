class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  layout :devise_layout

  private

  def devise_layout
    if devise_controller?
      "auth"
    else
      "application"
    end
  end
end
