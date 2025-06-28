class Users::RegistrationsController < Devise::RegistrationsController
  layout "devise"

  # Skip authenticate_user! for registration actions (new, create)
  # skip_before_action :authenticate_user!, only: [ :new, :create ]
end
