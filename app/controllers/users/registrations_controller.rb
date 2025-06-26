class Users::RegistrationsController < Devise::RegistrationsController
  layout 'devise'
  
  # Skip authenticate_user! for registration actions
  skip_before_action :authenticate_user!, except: [:show, :edit, :update, :destroy]
end