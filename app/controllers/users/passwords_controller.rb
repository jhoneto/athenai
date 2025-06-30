class Users::PasswordsController < Devise::PasswordsController
  layout "devise"

  # Skip authenticate_user! for password reset
  # skip_before_action :authenticate_user!
end
