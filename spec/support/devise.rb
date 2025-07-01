# frozen_string_literal: true

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view

  config.before(:each, type: :controller) do
    Rails.application.reload_routes_unless_loaded
  end

  config.before(:each, type: :view) do
    Rails.application.reload_routes_unless_loaded
  end
end
