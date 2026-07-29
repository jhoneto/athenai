# Plano 5 — Connector Layer: HTTP & OpenAPI

> Primeiro tipo de conector do Connector Layer (ver `doc/architecture.md` §4). Estabelece o contrato de adapter que o Plano 6 (bancos de dados) reaproveita.

## Objetivo

- `Connector` genérico (tabela única, `kind` enum) + `Connector::Credential` (segredos) + `Connector::Action` (capacidades chamáveis)
- Adapter `Connector::Adapters::Http` para chamar endpoints REST cadastrados manualmente
- Adapter `Connector::Adapters::OpenApi` + `Connector::OpenApiImporter` para importar uma spec e gerar `Connector::Action` automaticamente
- **Sem Tool Engine ainda** (Fase 2) — este plano entrega a capacidade de testar e executar ações de conector isoladamente pelo Dashboard, para validação manual

## Migrations

```ruby
class CreateConnectors < ActiveRecord::Migration[8.1]
  def change
    create_table :connectors do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :kind, null: false
      t.string  :name, null: false
      t.text    :description
      t.jsonb   :config, null: false, default: {}
      t.integer :status, null: false, default: 0   # pending, connected, error, disabled
      t.timestamps
    end

    add_index :connectors, [ :account_id, :name ], unique: true
  end
end

class CreateConnectorCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :connector_credentials do |t|
      t.references :connector, null: false, foreign_key: true, index: { unique: true }
      t.text :encrypted_secrets, null: false
      t.datetime :expires_at
      t.timestamps
    end
  end
end

class CreateConnectorActions < ActiveRecord::Migration[8.1]
  def change
    create_table :connector_actions do |t|
      t.references :connector, null: false, foreign_key: true
      t.string  :name, null: false
      t.text    :description
      t.integer :kind, null: false   # query, http_call, graphql_call, file_search
      t.jsonb   :input_schema, null: false, default: {}
      t.jsonb   :definition, null: false, default: {}
      t.timestamps
    end

    add_index :connector_actions, [ :connector_id, :name ], unique: true
  end
end
```

## Models

`app/models/connector.rb`

```ruby
class Connector < ApplicationRecord
  belongs_to :account
  has_one  :credential, class_name: "Connector::Credential", dependent: :destroy
  has_many :actions, class_name: "Connector::Action", dependent: :destroy

  enum :kind, {
    postgres: 0, mysql: 1, sqlserver: 2, oracle: 3,
    rest: 4, graphql: 5, openapi: 6,
    gmail: 7, microsoft365: 8, google_drive: 9, sharepoint: 10, s3: 11
  }
  enum :status, { pending: 0, connected: 1, error: 2, disabled: 3 }

  validates :name, presence: true, uniqueness: { scope: :account_id }

  def adapter
    "Connector::Adapters::#{kind.camelize}".constantize.new(self)
  end
end
```

`app/models/connector/credential.rb`

```ruby
class Connector::Credential < ApplicationRecord
  self.table_name = "connector_credentials"

  belongs_to :connector

  encrypts :encrypted_secrets

  validates :encrypted_secrets, presence: true
end
```

`app/models/connector/action.rb`

```ruby
class Connector::Action < ApplicationRecord
  self.table_name = "connector_actions"

  belongs_to :connector

  enum :kind, { query: 0, http_call: 1, graphql_call: 2, file_search: 3 }

  validates :name, presence: true, uniqueness: { scope: :connector_id }
  validates :input_schema, :definition, presence: true
end
```

`Account` ganha `has_many :connectors, dependent: :destroy`.

## Contrato de Adapter

`app/models/connector/adapters/base.rb`

```ruby
module Connector::Adapters
  class Base
    class ExecutionError < StandardError; end

    def initialize(connector)
      @connector = connector
      @credential = connector.credential
    end

    def test_connection!
      raise NotImplementedError
    end

    def call(action, params)
      raise NotImplementedError
    end
  end
end
```

## Adapter HTTP

`app/models/connector/adapters/http.rb`

```ruby
class Connector::Adapters::Http < Connector::Adapters::Base
  TIMEOUT = 10

  def test_connection!
    response = connection.get(@connector.config["health_path"] || "/")
    @connector.update!(status: response.success? ? :connected : :error)
  end

  def call(action, params)
    definition = action.definition
    response = connection.public_send(
      definition["method"].downcase,
      definition["path"],
      params
    )
    raise ExecutionError, "HTTP #{response.status}" unless response.success?

    response.body
  end

  private

  def connection
    Faraday.new(url: @connector.config["base_url"]) do |f|
      f.request :json
      f.response :json
      f.options.timeout = TIMEOUT
      f.headers["Authorization"] = "Bearer #{@credential&.encrypted_secrets&.dig('api_key')}" if @credential
    end
  end
end
```

Gem: adicionar `gem "faraday"` ao Gemfile.

## Adapter OpenAPI + Importer

`app/models/connector/adapters/open_api.rb` herda de `Http` (uma spec OpenAPI é só um conjunto de `Connector::Action` do tipo `http_call` com `definition` derivada da spec) — não precisa de lógica própria de execução, apenas reaproveita `Connector::Adapters::Http#call`.

```ruby
class Connector::Adapters::OpenApi < Connector::Adapters::Http
end
```

`app/models/connector/open_api_importer.rb` (chama API externa para buscar a spec — extraído por regra do fluxograma de decisão)

```ruby
class Connector::OpenApiImporter
  def initialize(connector)
    @connector = connector
  end

  def call
    spec = fetch_spec
    spec["paths"].each do |path, operations|
      operations.each do |method, operation|
        next unless %w[get post put patch delete].include?(method)

        @connector.actions.find_or_create_by!(name: operation["operationId"] || "#{method}_#{path}") do |action|
          action.kind = :http_call
          action.description = operation["summary"]
          action.input_schema = build_input_schema(operation)
          action.definition = { "method" => method, "path" => path }
        end
      end
    end
  end

  private

  def fetch_spec
    JSON.parse(Faraday.get(@connector.config["spec_url"]).body)
  end

  def build_input_schema(operation)
    properties = (operation["parameters"] || []).index_by { |p| p["name"] }
      .transform_values { |p| p["schema"] || { "type" => "string" } }

    { "type" => "object", "properties" => properties }
  end
end
```

## Job de teste de conexão

`app/jobs/connector/test_connection_job.rb`

```ruby
class Connector::TestConnectionJob < ApplicationJob
  queue_as :default

  def perform(connector_id)
    Connector.find(connector_id).adapter.test_connection!
  end
end
```

## Controllers (Dashboard)

`app/controllers/connectors_controller.rb`

```ruby
class ConnectorsController < ApplicationController
  before_action :set_connector, only: %i[show destroy test]

  def index
    @connectors = current_account.connectors.order(:name)
  end

  def new
    @connector = current_account.connectors.new
  end

  def create
    @connector = current_account.connectors.new(connector_params)
    if @connector.save
      Connector::TestConnectionJob.perform_later(@connector.id)
      redirect_to @connector
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def test
    Connector::TestConnectionJob.perform_later(@connector.id)
    redirect_to @connector, notice: "Testando conexão..."
  end

  def destroy
    @connector.destroy
    redirect_to connectors_path
  end

  private

  def set_connector
    @connector = current_account.connectors.find(params[:id])
  end

  def connector_params
    params.require(:connector).permit(:kind, :name, :description, config: {})
  end
end
```

`app/controllers/connector_actions_controller.rb` — CRUD de `Connector::Action` aninhado em connector (index/new/create/destroy), e uma action `import` que dispara `Connector::OpenApiImporter` via job (`Connector::ImportOpenApiJob`) quando `kind == "openapi"`.

## Rotas

```ruby
resources :connectors do
  member { post :test }
  resources :actions, controller: "connector_actions", only: %i[index new create destroy] do
    collection { post :import }
  end
end
```

## Views

- `app/views/connectors/index.html.erb` — lista com badge de `status`
- `app/views/connectors/_form.html.erb` — select de `kind`, campos de `config` dinâmicos (base_url, spec_url) via Stimulus (`connector_form_controller.js` mostra/esconde campos conforme `kind` selecionado)
- `app/views/connector_actions/index.html.erb` — lista de ações cadastradas/importadas, com botão "Testar" (executa a ação com params de exemplo e mostra o resultado bruto — útil para validar antes de virar `Tool` no Plano futuro de Tool Engine)

## Testes

- `spec/models/connector_spec.rb`, `spec/models/connector/credential_spec.rb`, `spec/models/connector/action_spec.rb`
- `spec/models/connector/adapters/http_spec.rb` — usa `WebMock`/`VCR` (adicionar `gem "webmock"` ao grupo `:test`) para simular respostas HTTP, nunca bate em rede real
- `spec/models/connector/open_api_importer_spec.rb` — spec OpenAPI fixture em `spec/fixtures/files/openapi_sample.json`
- `spec/jobs/connector/test_connection_job_spec.rb`
- `spec/requests/connectors_spec.rb`, `spec/requests/connector_actions_spec.rb`

## Critérios de aceite

- [ ] Conector HTTP testável e com status refletindo o resultado real
- [ ] Import de OpenAPI gera `Connector::Action` automaticamente, sem duplicar em reimportações (`find_or_create_by!`)
- [ ] Segredos de conector nunca aparecem em texto puro na UI/logs
- [ ] Nenhum teste depende de rede real (WebMock obrigatório)
