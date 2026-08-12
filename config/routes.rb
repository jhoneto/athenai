Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  resource :billing, only: [ :show ], controller: "billing"

  resources :agents do
    member { post :publish }
  end

  namespace :webhooks do
    post :stripe, to: "stripe#create"
  end

  authenticated :user do
    root to: redirect("/billing"), as: :authenticated_root
  end

  devise_scope :user do
    root to: "devise/sessions#new"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
