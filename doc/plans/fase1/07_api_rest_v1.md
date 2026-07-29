# Plano 7 — API REST v1 + Swagger

> Expõe as capacidades dos Planos 1–6 para o software cliente (Aurora, ERP, CRM). Feito por último pois consolida endpoints de todos os módulos anteriores. Ver `doc/architecture.md` §7.

## Objetivo

- Autenticação por `ApiKey` (não é o mesmo login por sessão do Dashboard)
- Endpoints REST em `Api::V1::*`, namespace separado do Dashboard (`app/controllers/api/v1/`)
- Documentação Swagger/OpenAPI gerada a partir das request specs (`rswag`)

## Migration — `ApiKey`

```ruby
class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :prefix, null: false          # ex.: "ath_live_ab12" — parte visível, para o usuário identificar a chave
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :api_keys, :token_digest, unique: true
    add_index :api_keys, :prefix, unique: true
  end
end
```

## Model

`app/models/api_key.rb`

```ruby
class ApiKey < ApplicationRecord
  belongs_to :account

  validates :name, presence: true

  scope :active, -> { where(revoked_at: nil) }

  class << self
    def create_with_token!(account:, name:)
      raw_token = SecureRandom.hex(24)
      prefix = "ath_live_#{raw_token[0, 8]}"

      key = create!(account: account, name: name, prefix: prefix, token_digest: digest(raw_token))
      [ key, "#{prefix}.#{raw_token}" ]
    end

    def authenticate(token)
      prefix, raw_token = token.to_s.split(".", 2)
      return nil if prefix.blank? || raw_token.blank?

      active.find_by(prefix: prefix, token_digest: digest(raw_token))
    end

    private

    def digest(raw_token)
      Digest::SHA256.hexdigest(raw_token)
    end
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
```

`Account` ganha `has_many :api_keys, dependent: :destroy`.

O token completo (`prefix.raw_token`) só é exibido **uma vez**, no momento da criação — nunca reconstruído depois (só o `token_digest` é persistido).

## Autenticação da API

`app/controllers/api/v1/base_controller.rb`

```ruby
class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_key!

  private

  def authenticate_api_key!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    @api_key = ApiKey.authenticate(token)

    render json: { error: "unauthorized" }, status: :unauthorized and return unless @api_key
    @api_key.touch(:last_used_at)
  end

  def current_account
    @api_key.account
  end
end
```

## Controllers da API (finos, delegam para os models já existentes)

`app/controllers/api/v1/agents_controller.rb`

```ruby
class Api::V1::AgentsController < Api::V1::BaseController
  def index
    render json: current_account.agents.available
  end

  def show
    render json: current_account.agents.available.find(params[:id])
  end
end
```

`app/controllers/api/v1/sessions_controller.rb`

```ruby
class Api::V1::SessionsController < Api::V1::BaseController
  def create
    agent = current_account.agents.available.find(params[:agent_id])
    session = current_account.sessions.create!(agent: agent, user: system_user)
    render json: session, status: :created
  end

  private

  def system_user
    current_account.users.first # MVP: sessão via API roda em nome do primeiro usuário do account;
  end                           # revisar quando houver conceito de "usuário final" desacoplado de User (Fase 2)
end
```

`app/controllers/api/v1/messages_controller.rb`

```ruby
class Api::V1::MessagesController < Api::V1::BaseController
  def create
    session = current_account.sessions.find(params[:session_id])
    session.messages.create!(role: :user, content: message_params[:content])
    AgentResponseJob.perform_later(session.id, message_params[:content])

    render json: { status: "queued" }, status: :accepted
  end

  def index
    session = current_account.sessions.find(params[:session_id])
    render json: session.messages
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
```

`app/controllers/api/v1/connectors_controller.rb`, `app/controllers/api/v1/connector_actions_controller.rb` — expõem create/index dos models do Plano 5/6, mesma estrutura enxuta (reaproveitam validações já existentes nos models, controller só traduz para JSON).

## Rotas

```ruby
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
```

## Swagger

Gems: `gem "rswag-api"`, `gem "rswag-ui"` (produção) e `gem "rswag-specs"` (grupo `:test`).

```ruby
# config/initializers/rswag_api.rb
Rswag::Api.configure { |c| c.swagger_root = Rails.root.join("swagger").to_s }

# config/initializers/rswag_ui.rb
Rswag::Ui.configure { |c| c.swagger_endpoint "/api-docs/v1/swagger.yaml", "API V1" }
```

`config/routes.rb`:

```ruby
mount Rswag::Ui::Engine  => "/api-docs"
mount Rswag::Api::Engine => "/api-docs"
```

As specs de request em `spec/requests/api/v1/*_spec.rb` usam a DSL do `rswag-specs` (`path`, `response`) para descrever cada endpoint — rodar `rails rswag:specs:swaggerize` gera `swagger/v1/swagger.yaml`, servido pelo `rswag-api` e renderizado pela UI do `rswag-ui`. A mesma spec que testa o endpoint documenta o endpoint — sem duplicar esforço.

## Rate limiting (mínimo viável para MVP)

Usar `Rack::Attack` (adicionar `gem "rack-attack"`) com limite por `ApiKey#prefix`, configurado em `config/initializers/rack_attack.rb`. Detalhamento de regras fica fora do escopo deste plano (revisar na Fase 2 junto com "Auditoria"/"Observabilidade").

## Testes

- `spec/models/api_key_spec.rb` — `create_with_token!` retorna token só uma vez, `authenticate` funciona e falha corretamente, `revoke!`
- `spec/requests/api/v1/agents_spec.rb`, `.../sessions_spec.rb`, `.../messages_spec.rb`, `.../connectors_spec.rb` — todas usando a DSL `rswag` para já gerar documentação; cobrir 401 sem `ApiKey` válida, isolamento entre accounts (uma `ApiKey` de um account nunca acessa dados de outro)

## Critérios de aceite

- [ ] Token de API só é exibido uma vez, nunca reconstruído
- [ ] Toda rota de `Api::V1` exige `ApiKey` válida e não revogada
- [ ] `/api-docs` renderiza a documentação Swagger gerada a partir das specs
- [ ] Isolamento total entre accounts validado em request specs
