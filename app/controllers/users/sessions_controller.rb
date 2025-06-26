class Users::SessionsController < Devise::SessionsController
  layout "devise"

  # Skip authenticate_user! for sessions controller
  skip_before_action :authenticate_user!
end
