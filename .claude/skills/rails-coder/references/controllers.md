# Padrões de Controller

## Meta: 5-10 Linhas por Action

Controllers devem ser orquestradores enxutos. Eles lidam apenas com responsabilidades HTTP:
- Verificações de autenticação/autorização
- Manipulação de parâmetros
- Operações no model (CRUD simples)
- Enfileiramento de jobs
- Renderização de resposta

## Athenai: Dois Contextos de Auth

O Athenai tem dois namespaces de controller com autenticações distintas:

### 1. API Externa (autenticação por API Key)

Para integrações programáticas.

```ruby
# app/controllers/api/v1/application_controller.rb
class Api::V1::ApplicationController < ActionController::API
  before_action :authenticate_api_key!

  private

  def current_account
    @current_account ||= begin
      token = request.headers["X-Api-Key"]
      ApiKey.active.find_by!(token: token).account
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end

  def authenticate_api_key!
    head :unauthorized unless current_account
  end
end
```

### 2. Dashboard Web (autenticação via Devise)

Para usuários humanos acessando o painel.

```ruby
# app/controllers/dashboard/application_controller.rb
class Dashboard::ApplicationController < ApplicationController
  before_action :authenticate_user!  # Devise

  private

  def current_account
    @current_account ||= current_user.accounts.first
  end
  helper_method :current_account
end

# app/controllers/dashboard/users_controller.rb
class Dashboard::UsersController < Dashboard::ApplicationController
  def index
    @users = current_account.users.order(:name)
  end
end
```

## Guard Clauses

Use guard clauses para retornos antecipados:

```ruby
def create
  return head :forbidden unless current_user.owner_of?(current_account)

  @resource = current_account.resources.create!(resource_params)
  redirect_to @resource, notice: "Criado com sucesso"
rescue ActiveRecord::RecordInvalid => e
  @resource = e.record
  render :new, status: :unprocessable_entity
end
```

## Rotas

```ruby
Rails.application.routes.draw do
  root "home#index"

  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  namespace :dashboard do
    resource :account, only: [:show, :edit, :update]
    resources :members, only: [:index, :destroy]
  end

  # API externa (futuro)
  namespace :api do
    namespace :v1 do
      get :ping, to: "ping#show"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

## Manipulação de Parâmetros

### Strong Parameters

```ruby
def user_params
  params.require(:user).permit(:name, :email, :password, :password_confirmation)
end
```

## Padrões de Resposta

### Respostas HTML (Dashboard)

```ruby
def create
  @resource = current_account.resources.create!(resource_params)
  redirect_to dashboard_resource_path(@resource), notice: "Recurso criado"
rescue ActiveRecord::RecordInvalid => e
  @resource = e.record
  render :new, status: :unprocessable_entity
end
```

### Respostas Turbo Stream

```ruby
def create
  @resource = current_account.resources.create!(resource_params)
  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to dashboard_resource_path(@resource) }
  end
rescue ActiveRecord::RecordInvalid => e
  @resource = e.record
  render :new, status: :unprocessable_entity
end
```

## Tratamento de Erros

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
```

## Anti-Padrões a Evitar

### Lógica de Negócio em Controllers

```ruby
# Ruim — lógica demais
def create
  @user = User.new(user_params)
  # processar lógica de negócio aqui...
end

# Bom — delegar para model/job
def create
  @user = current_account.users.create!(user_params)
  OnboardingJob.perform_later(@user)
  redirect_to dashboard_path
end
```

## Testando Controllers

Teste através de request specs, não controller specs:

```ruby
# spec/requests/dashboard/users_spec.rb
RSpec.describe "Dashboard::Users" do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  before do
    create(:account_user, account: account, user: user, role: :owner)
    sign_in user
  end

  describe "GET /dashboard/users" do
    it "retorna a lista de usuários" do
      get dashboard_users_path
      expect(response).to have_http_status(:ok)
    end
  end
end
```
