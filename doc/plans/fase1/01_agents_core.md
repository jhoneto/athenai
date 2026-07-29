# Plano 1 — Agents Core

> Fundação da plataforma: cadastro de `Agent` dentro de um `Account`, com prompt e seleção de um AI Profile (o modelo real por trás é um detalhe interno).
>
> **Atualizado por [`00_ruby_llm_setup.md`](../00_ruby_llm_setup.md)** e por [`doc/cobrancao.md`](../../cobrancao.md): `Agent` referencia `Llm::Profile` (`Fast`/`Balanced`/`Premium`/`Deep Reasoning`), nunca `Llm::Model`/provider diretamente — o cliente escolhe uma experiência, não um provedor. O Plano 0 deve ser implementado antes deste.

## Objetivo

Permitir que um `Account` cadastre, edite, publique e arquive agentes através do Dashboard. Nenhuma execução de LLM ainda — apenas o CRUD e as regras de domínio.

## Migration

```ruby
class CreateAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :agents do |t|
      t.references :account, null: false, foreign_key: true
      t.references :llm_profile, null: true, foreign_key: { to_table: :llm_profiles }
      t.string  :name, null: false
      t.text    :description
      t.text    :system_prompt, null: false, default: ""
      t.float   :temperature, null: false, default: 0.7
      t.integer :status, null: false, default: 0
      t.timestamps
    end

    add_index :agents, [ :account_id, :name ], unique: true
  end
end
```

Requer que a tabela `llm_profiles` já exista — ver [Plano 0](../00_ruby_llm_setup.md), que precede este.

## Model

`app/models/agent.rb`

```ruby
class Agent < ApplicationRecord
  belongs_to :account
  belongs_to :llm_profile, class_name: "Llm::Profile", optional: true

  enum :status, { draft: 0, published: 1, archived: 2 }

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :temperature, numericality: { in: 0.0..2.0 }

  scope :available, -> { published }

  delegate :provider, :model_id, to: :llm_model, allow_nil: true

  def llm_model
    llm_profile&.llm_model
  end

  def publishable?
    system_prompt.present? && llm_model.present?
  end

  def publish!
    raise ActiveRecord::RecordInvalid, self unless publishable?
    update!(status: :published)
  end
end
```

`llm_profile` só pode ser um dos perfis retornados por `Llm::ProfileCatalog.new(account).selectable_profiles` (ver Plano 0, seção 4) — validado no controller ao montar o `<select>`, não no model, pois o gate por plano (`Plan::FEATURES`) pode mudar sem exigir migração.

`Account` ganha a associação:

```ruby
# app/models/account.rb
has_many :agents, dependent: :destroy
```

Não é necessário extrair nada para namespace neste plano — toda a lógica cabe no model (< 15 linhas por método).

## Controller (Dashboard)

`app/controllers/agents_controller.rb` (fora de namespace, seguindo o padrão atual do projeto onde recursos do dashboard ficam na raiz de `app/controllers`, como `billing_controller.rb`)

```ruby
class AgentsController < ApplicationController
  before_action :set_agent, only: %i[show edit update destroy publish]

  def index
    @agents = current_account.agents.order(:name)
  end

  def show; end

  def new
    @agent = current_account.agents.new
    @llm_profiles = Llm::ProfileCatalog.new(current_account).selectable_profiles
  end

  def create
    @agent = current_account.agents.new(agent_params)
    @agent.save ? redirect_to(@agent) : render(:new, status: :unprocessable_entity)
  end

  def edit
    @llm_profiles = Llm::ProfileCatalog.new(current_account).selectable_profiles
  end

  def update
    @agent.update(agent_params) ? redirect_to(@agent) : render(:edit, status: :unprocessable_entity)
  end

  def publish
    @agent.publish!
    redirect_to @agent
  rescue ActiveRecord::RecordInvalid
    redirect_to @agent, alert: "Agente incompleto para publicação"
  end

  def destroy
    @agent.destroy
    redirect_to agents_path
  end

  private

  def set_agent
    @agent = current_account.agents.find(params[:id])
  end

  def agent_params
    params.require(:agent).permit(:name, :description, :system_prompt, :llm_profile_id, :temperature)
  end
end
```

## Rotas

```ruby
resources :agents do
  member { post :publish }
end
```

## Views

- `app/views/agents/index.html.erb` — tabela com nome, status (badge Tailwind), perfil de IA (`Fast`/`Balanced`/`Premium`/`Deep Reasoning`)
- `app/views/agents/_form.html.erb` — campos: nome, descrição, system_prompt (textarea), `llm_profile_id` (select carregado de `@llm_profiles` — apenas os 4 perfis, nunca um `Llm::Model` bruto), temperature (range input)
- `app/views/agents/show.html.erb` — detalhes + botão publicar/arquivar
- Sem Stimulus controller necessário neste plano (formulário simples)

## Testes

`spec/factories/agents.rb`

```ruby
FactoryBot.define do
  factory :agent do
    account
    llm_profile
    name { Faker::App.name }
    system_prompt { "You are a helpful assistant." }
  end
end
```

- `spec/models/agent_spec.rb` — validations, `publish!` com/sem prompt, uniqueness por account, `llm_model` delega corretamente de `llm_profile`
- `spec/requests/agents_spec.rb` — CRUD completo, garantindo que um account não acesse agentes de outro (`current_account.agents.find` já isola, mas o teste deve provar o 404); `new`/`edit` só listam perfis liberados pelo plano do account

## Critérios de aceite

- [ ] Um account só vê/edita seus próprios agentes
- [ ] Agente não publica sem `system_prompt` nem `llm_profile`
- [ ] O `<select>` de perfil só lista o que `Llm::ProfileCatalog` retorna para o account (nunca `Llm::Profile`/`Llm::Model` inteiros, nem perfis fora do plano contratado)
- [ ] `status` exposto como badge na UI
- [ ] Testes cobrindo isolamento de tenant
