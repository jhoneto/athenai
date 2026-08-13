Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  resource :billing, only: [ :show ], controller: "billing"

  resources :agents do
    member { post :publish }
    resources :documents, only: %i[index create destroy]
  end

  resources :llm_credentials, only: %i[index new create destroy]

  resources :connectors do
    member { post :test }
    resources :actions, controller: "connector_actions", only: %i[index new create destroy] do
      collection { post :import }
      member { post :test }
    end
  end

  resources :chat_sessions, controller: "sessions", only: %i[index show create destroy] do
    resources :messages, only: :create
  end

  namespace :api do
    namespace :v1 do
      resources :agents, only: %i[index show]
      resources :sessions, only: :create do
        resources :messages, only: %i[index create]
      end
      resources :connectors, only: %i[index create show] do
        resources :actions, controller: "connector_actions", only: %i[index create]
      end
    end
  end

  get "docs", to: "docs#api", as: :docs

  mount Rswag::Ui::Engine => "/api-docs", as: :api_docs
  mount Rswag::Api::Engine => "/api-docs"

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
