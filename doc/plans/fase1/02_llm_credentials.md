# Plano 2 — LLM Credentials & integração RubyLLM

> Implementa a promessa: "hoje usamos nossas próprias chaves, no futuro cada account pode ter a sua". Sem mudar a interface pública do Agent Engine.
>
> Depende do [Plano 0](../00_ruby_llm_setup.md) — a configuração global do `RubyLLM` (initializer, `use_new_acts_as`, `model_registry_class`) já foi feita lá. Este plano cobre apenas o BYOK por account.

## Objetivo

- Permitir que um `Account` cadastre sua própria chave por provider (BYOK), criptografada
- Resolver, em runtime, qual chave usar para um `Agent`
- Restringir o cadastro de BYOK a accounts com a feature `"byok"` — conforme `doc/cobrancao.md`, hoje só o plano Enterprise

Chaves globais da plataforma já ficam em `config/credentials.yml.enc` desde o Plano 0 (nunca em `.env` versionado) — documentar no `.kamal/secrets` as env vars equivalentes para produção (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`), conforme checklist da skill.

## Migration

```ruby
class CreateLlmCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_credentials do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :provider, null: false
      t.text    :encrypted_api_key, null: false
      t.timestamps
    end

    add_index :llm_credentials, [ :account_id, :provider ], unique: true
  end
end
```

## Model

`app/models/llm/credential.rb` (namespace `Llm::`)

```ruby
class Llm::Credential < ApplicationRecord
  self.table_name = "llm_credentials"

  belongs_to :account

  enum :provider, { openai: 0, anthropic: 1, gemini: 2, openrouter: 3, vllm: 4, ollama: 5 }

  encrypts :encrypted_api_key

  validates :provider, uniqueness: { scope: :account_id }
  validates :encrypted_api_key, presence: true
end
```

`Account` ganha:

```ruby
has_many :llm_credentials, class_name: "Llm::Credential", dependent: :destroy
```

## Resolver

`app/models/llm/resolver.rb`

```ruby
class Llm::Resolver
  def initialize(agent)
    @agent = agent
  end

  def context
    credential = @agent.account.llm_credentials.find_by(provider: @agent.provider)
    return RubyLLM if credential.blank?

    RubyLLM.context do |config|
      config.public_send("#{@agent.provider}_api_key=", credential.encrypted_api_key)
    end
  end
end
```

Isso é a única classe que sabe resolver credenciais — o `Agent::Runner` (Plano 3) apenas chama `Llm::Resolver.new(agent).context`.

## Controller (Dashboard)

`app/controllers/llm_credentials_controller.rb` — CRUD simples aninhado em `/settings/llm_credentials`, seguindo o mesmo padrão enxuto do Plano 1 (index/new/create/destroy; sem `edit/update` — trocar chave é destruir e recriar, evita reter estado inconsistente).

```ruby
class LlmCredentialsController < ApplicationController
  before_action :require_byok_feature!

  def index
    @llm_credentials = current_account.llm_credentials
  end

  def new
    @llm_credential = current_account.llm_credentials.new
  end

  def create
    @llm_credential = current_account.llm_credentials.new(llm_credential_params)
    @llm_credential.save ? redirect_to(llm_credentials_path) : render(:new, status: :unprocessable_entity)
  end

  def destroy
    current_account.llm_credentials.find(params[:id]).destroy
    redirect_to llm_credentials_path
  end

  private

  def require_byok_feature!
    redirect_to billing_path, alert: "BYOK disponível apenas no plano Enterprise" unless current_account.feature?("byok")
  end

  def llm_credential_params
    params.require(:llm_credential).permit(:provider, :encrypted_api_key)
  end
end
```

## Rotas

```ruby
resources :llm_credentials, only: %i[index new create destroy]
```

## Views

- `app/views/llm_credentials/index.html.erb` — lista por provider, chave sempre mascarada (`****...ab12`), nunca exibir valor completo após salvar
- `app/views/llm_credentials/_form.html.erb` — select de provider + campo de chave (password field)

## Testes

- `spec/models/llm/credential_spec.rb` — uniqueness por provider/account, presença, que o valor é de fato criptografado no banco (`described_class.encrypted_attribute?(:encrypted_api_key)` ou verificando a coluna raw)
- `spec/models/llm/resolver_spec.rb` — com credencial de account → usa a chave do account; sem credencial → cai para configuração global (mock de `RubyLLM.context`)
- `spec/requests/llm_credentials_spec.rb` — CRUD e isolamento por account; account sem a feature `"byok"` recebe redirect em todas as actions

## Critérios de aceite

- [ ] Plataforma funciona out-of-the-box com chaves globais (nenhum account precisa cadastrar nada)
- [ ] Somente accounts com a feature `"byok"` (Enterprise) conseguem cadastrar `Llm::Credential`
- [ ] Account elegível pode sobrepor com sua própria chave por provider
- [ ] Chave nunca aparece em texto puro na UI após o cadastro
- [ ] `Llm::Resolver` é a única classe que decide isso — nenhum outro lugar do código acessa `Llm::Credential` diretamente
