Rails.application.routes.draw do
  get "home/index"
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  resources :workspaces do
    resources :functions do
      member do
        get :execute
        post :run
      end
    end
    resources :llms
    resources :mcp_servers
    resources :agents do
      resources :agent_functions, only: [ :index, :create, :destroy ]
      resources :agent_mcp_servers, only: [ :index, :create, :destroy ]
      resources :chats, only: [ :index, :show, :create ] do
        member do
          post :create_message
        end
      end
    end
  end

  namespace :api do
    scope ":workspace_api_key" do
      resources :messages, only: [ :create ]
    end
  end
end
