# Plano 0 — Setup do RubyLLM & Catálogo de Modelos

> Pré-requisito da [Fase 1](fase1/00_overview.md). Antes de existir `Agent`, `Session` ou qualquer coisa que fale com um LLM, a plataforma precisa de uma forma confiável de saber **quais modelos existem, de quais providers, e com quais características** (contexto, custo, capacidades). Baseado em `ruby_llm` v1.16 (já presente no `Gemfile`) — https://rubyllm.com e https://rubyllm.com/models/.

## 1. Objetivo

- Configurar o `RubyLLM` para os **três providers iniciais**: OpenAI, Anthropic, Gemini
- Trazer o **catálogo de modelos para o nosso banco** (não depender só do JSON estático embutido na gem), para poder consultar contexto/custo/capacidades e manter uma allowlist própria
- Modelar o **catálogo técnico** (`Llm::Model`) totalmente separado da **experiência comercial** (`Llm::Profile`) — a decisão de exposição que ficava em aberto neste plano foi **resolvida** por [`doc/cobrancao.md`](../cobrancao.md): o cliente nunca escolhe provider/modelo, ele escolhe um **AI Profile** (`Fast`/`Balanced`/`Premium`/`Deep Reasoning`). Ver seção 3

## 1.1. Decisão resolvida: AI Profiles, não seleção direta

`doc/cobrancao.md` decide isso por nós: **"o cliente nunca compra tokens, ele compra capacidade de execução"**. Isso descarta as opções de seleção livre e de aliases arbitrários — a plataforma expõe exatamente 4 perfis fixos, com multiplicador de créditos definido no documento de cobrança (`Fast` 1x, `Balanced` 2x, `Premium` 5x, `Deep Reasoning` 10x). Cada perfil aponta para **um único** `Llm::Model` por vez — trocável pela administração sem qualquer impacto comercial ou de código (`Fast` pode migrar de `gpt-5-mini` para `gemini-flash` sem o cliente notar).

O acesso a cada perfil é **gated por plano** (Starter só tem `Fast`; Professional tem `Fast`/`Balanced`/`Premium`; Enterprise tem todos + `byok`) — reaproveitando o mecanismo já existente em `Plan::FEATURES`.

## 2. Por que isso não pode esperar a Fase 1

O Plano 1 da Fase 1 (`Agent`) originalmente previa `provider`/`model` como colunas de texto livre. Investigando a gem, isso é a abordagem errada por dois motivos:

1. A gem já oferece um **registro de modelos ativo (Active Record)** via `acts_as_model` — reinventar isso com strings soltas joga fora contexto/custo/capacidades que a gem mantém atualizados
2. `RubyLLM.models.refresh!` **não se limita aos providers configurados**: ele também importa metadados de todos os providers listados em [models.dev](https://models.dev), incluindo os que não configuramos (DeepSeek, Mistral, xAI, Bedrock, etc). Sem uma allowlist explícita, nosso catálogo "vaza" providers que não vamos suportar e não temos como cobrar

Por isso este plano existe separado e antes da Fase 1 — ele muda o desenho dos Planos 1–3 da Fase 1, detalhado na seção 10.

## 3. `Llm::Profile` — a unidade que o cliente vê

`Plan::FEATURES` (já implementado em `app/models/plan.rb`) precisa ganhar entradas por perfil e por BYOK — dado de configuração, não mudança estrutural:

```ruby
FEATURES = {
  "starter"    => %w[... profile_fast],
  "growth"     => %w[... profile_fast profile_balanced profile_premium],   # "Professional" em doc/cobrancao.md
  "enterprise" => %w[... profile_fast profile_balanced profile_premium profile_deep_reasoning byok]
}
```

> **Nota**: `doc/cobrancao.md` chama o plano intermediário de "Professional", mas o slug já implementado em `Plan` é `"growth"`. Alinhar o nome (renomear o slug ou usar "Professional" só como *label* de exibição) é uma decisão de produto que fica fora deste plano — sinalizar ao decidir a tela de billing.

Migration:

```ruby
class CreateLlmProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_profiles do |t|
      t.integer :key, null: false
      t.string  :name, null: false
      t.references :llm_model, foreign_key: { to_table: :llm_models }
      t.decimal :credit_multiplier, precision: 6, scale: 2, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :llm_profiles, :key, unique: true
  end
end
```

`app/models/llm/profile.rb`

```ruby
class Llm::Profile < ApplicationRecord
  self.table_name = "llm_profiles"

  belongs_to :llm_model, optional: true   # nil até a administração configurar o modelo real

  enum :key, { fast: 0, balanced: 1, premium: 2, deep_reasoning: 3 }

  scope :active, -> { where(active: true) }
  scope :configured, -> { where.not(llm_model_id: nil) }

  validates :name, presence: true
  validates :credit_multiplier, numericality: { greater_than: 0 }
end
```

Os 4 perfis são dado de catálogo fixo (multiplicadores definidos em `doc/cobrancao.md`), não algo criado pelo usuário — semeados via `db/seeds.rb`:

```ruby
{ fast: 1, balanced: 2, premium: 5, deep_reasoning: 10 }.each do |key, multiplier|
  Llm::Profile.find_or_create_by!(key: key) do |profile|
    profile.name = key.to_s.titleize
    profile.credit_multiplier = multiplier
  end
end
```

`llm_model_id` fica `nil` até a administração associar um modelo real via console/Dashboard (não há como adivinhar o `model_id` correto no seed) — `Llm::Profile.configured` filtra os perfis prontos para uso.

## 4. `Llm::ProfileCatalog` — ponto único de decisão

```ruby
class Llm::ProfileCatalog
  def initialize(account)
    @account = account
  end

  def selectable_profiles
    Llm::Profile.active.configured.select { |profile| @account.feature?("profile_#{profile.key}") }
  end
end
```

Todo controller/view do Dashboard e todo endpoint da `Api::V1` que precisa saber "quais perfis este account pode usar" consulta **somente** esta classe — nunca `Llm::Profile` ou `Llm::Model` diretamente. Isso é o que sobra da "decisão em aberto" original: hoje o gate é por `Plan::FEATURES`; se amanhã vender add-ons avulsos de perfil, só esta classe muda.

## 5. Escopo: apenas 3 providers

`RubyLLM.models.refresh!` só busca modelos de providers com API key configurada (`Provider.configured_remote_providers`). Configurando **apenas** `openai_api_key`, `anthropic_api_key` e `gemini_api_key`, nenhum outro provider é consultado diretamente — mas o enriquecimento via models.dev (seção 2) ainda pode inserir metadados de outros providers no resultado combinado. Por isso o modelo `Llm::Model` (seção 6) aplica uma **allowlist explícita** (`SUPPORTED_PROVIDERS`), removendo qualquer provider fora da lista após cada `refresh!` — defesa em profundidade, não confiar apenas em "só configuramos 3 chaves".

## 6. Initializer

`config/initializers/ruby_llm.rb`

```ruby
RubyLLM.configure do |config|
  config.openai_api_key    = Rails.application.credentials.dig(:openai, :api_key)
  config.anthropic_api_key = Rails.application.credentials.dig(:anthropic, :api_key)
  config.gemini_api_key    = Rails.application.credentials.dig(:gemini, :api_key)

  # Habilita a API baseada em associações (Chat/Message podem referenciar Model)
  config.use_new_acts_as = true

  # Nosso catálogo de modelos vive no Llm::Model, não no JSON embutido na gem
  config.model_registry_class = "Llm::Model"

  config.request_timeout = 30
end
```

Documentar em `.kamal/secrets` as env vars equivalentes de produção: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` — nunca versionar as chaves reais, só a referência de que existem (regra do checklist da skill `rails-coder`).

**Nota**: por ora a plataforma usa exclusivamente as chaves globais (`Rails.application.credentials`). O suporte a chave própria por account (BYOK) é tratado no Plano 2 da Fase 1 (`Llm::Credential`), que passa a ser resolvido *depois* deste plano — `Llm::Resolver` (Fase 1) troca a `api_key` do provider em runtime, mas o catálogo de modelos disponíveis continua vindo daqui, do `Llm::Model`.

## 7. Migration — `llm_models`

```ruby
class CreateLlmModels < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_models do |t|
      t.string   :model_id, null: false
      t.string   :name, null: false
      t.string   :provider, null: false
      t.string   :family
      t.datetime :model_created_at
      t.integer  :context_window
      t.integer  :max_output_tokens
      t.date     :knowledge_cutoff
      t.jsonb    :modalities, null: false, default: {}
      t.jsonb    :capabilities, null: false, default: []
      t.jsonb    :pricing, null: false, default: {}
      t.jsonb    :metadata, null: false, default: {}
      t.boolean  :enabled, null: false, default: true
      t.timestamps

      t.index [ :provider, :model_id ], unique: true
      t.index :provider
      t.index :capabilities, using: :gin
    end
  end
end
```

Colunas iguais ao template `ruby_llm:install` (para reaproveitar `RubyLLM::ActiveRecord::ModelMethods` sem adaptação), **mais** `enabled` — coluna própria do Athenai para curadoria manual (ex.: desabilitar um modelo caro/experimental sem esperar o próximo `refresh!`).

## 8. Model — `Llm::Model`

`app/models/llm/model.rb`

```ruby
class Llm::Model < ApplicationRecord
  self.table_name = "llm_models"

  SUPPORTED_PROVIDERS = %w[openai anthropic gemini].freeze

  acts_as_model chats: :llm_profiles, chat_class: "Llm::Profile"

  scope :supported, -> { where(provider: SUPPORTED_PROVIDERS) }
  scope :selectable, -> { supported.where(enabled: true) } # candidatos a serem apontados por um Llm::Profile

  def self.refresh!
    super
    where.not(provider: SUPPORTED_PROVIDERS).delete_all
  end

  def label
    "#{name} (#{provider})"
  end
end
```

- `acts_as_model` vem da gem e injeta `refresh!`/`save_to_database`/`to_llm` (ver `RubyLLM::ActiveRecord::ModelMethods`) — o `super` dentro do nosso `refresh!` chama a implementação da gem (fetch + upsert) antes de aplicarmos a limpeza de providers não suportados
- `chat_class: "Llm::Profile"` reaproveita o parâmetro `chats` da gem (pensado para "conversas") para expressar uma associação real do nosso domínio: `llm_model.llm_profiles` retorna quais perfis apontam para este modelo hoje — útil na tela administrativa antes de desativar um `Llm::Model` ("este modelo ainda é usado por `Fast` e `Balanced`")
- `label` é um helper de UI (não da gem), usado na tela administrativa onde se escolhe qual `Llm::Model` cada `Llm::Profile` aponta
- **`Llm::Model` não tem mais uma interface pública de "catálogo selecionável"** — quem decide o que o cliente pode escolher é o `Llm::Profile`/`Llm::ProfileCatalog` (seções 3 e 4). `Llm::Model.selectable` só é consultado pela tela administrativa que configura `llm_profiles.llm_model_id`

## 9. Atualização de refresh (job + rake)

`app/jobs/llm/model_refresh_job.rb`

```ruby
class Llm::ModelRefreshJob < ApplicationJob
  queue_as :default

  def perform
    Llm::Model.refresh!
  end
end
```

`lib/tasks/llm_models.rake` (task própria do Athenai — não confundir com a task interna `models:*` da gem, que é para manutenção da própria gem)

```ruby
namespace :llm_models do
  desc "Atualiza o catálogo de modelos (OpenAI/Anthropic/Gemini) a partir dos providers configurados"
  task refresh: :environment do
    Llm::Model.refresh!
    puts "#{Llm::Model.selectable.count} modelos habilitados após refresh"
  end
end
```

Rodar manualmente após deploy (`bin/rails llm_models:refresh`) ou agendar recorrência simples via `SolidQueue` (`Llm::ModelRefreshJob` enfileirada por um cron do `solid_queue` — configuração de recorrência fica fora do escopo deste plano, é só habilitar quando o catálogo precisar ficar sempre atualizado sem intervenção manual).

**Não** colocar o `refresh!` em `db/seeds.rb` — seeds rodam em ambientes sem rede/API key (CI, setup local) e o gem já lida bem com "zero modelos" apenas logando erro; preferir rodar a task manualmente ou via job após o initializer estar com chaves válidas.

## 10. Ajustes necessários na Fase 1

Este plano (já revisado após a leitura de `doc/cobrancao.md`) muda o desenho original dos Planos 1–3. Os arquivos já foram atualizados:

- **[`fase1/01_agents_core.md`](fase1/01_agents_core.md)**: `Agent` referencia `belongs_to :llm_profile, class_name: "Llm::Profile", optional: true` (não `Llm::Model` diretamente); `llm_model` vira um método (`llm_profile&.llm_model`) e `provider`/`model_id` continuam delegados a partir dele — o `<select>` do Dashboard usa `Llm::ProfileCatalog`, não mais `Llm::ModelCatalog` (que deixou de existir, seção 8)
- **[`fase1/02_llm_credentials.md`](fase1/02_llm_credentials.md)**: sem mudança de código — `Llm::Resolver` continua lendo `@agent.provider`/`model_id`, que agora resolvem através de `llm_profile.llm_model`. Cadastro de `Llm::Credential` (BYOK) passa a exigir `current_account.feature?("byok")` no controller
- **[`fase1/03_sessions_chat.md`](fase1/03_sessions_chat.md)**: `Session` ganha `llm_profile_id` (FK para `llm_profiles`, copiado de `agent.llm_profile_id` na criação — trocar o perfil do agente não altera conversas já iniciadas) e `Agent::Runner` usa `@session.llm_profile.llm_model.model_id`

A cobrança em si (débito de AI Credits a cada execução) é um plano novo, não uma alteração dos Planos 1–3: **[`fase1/08_ai_credits_cost_engine.md`](fase1/08_ai_credits_cost_engine.md)**.

## 11. Testes

- `spec/models/llm/model_spec.rb` — `refresh!` mockado (stub em `RubyLLM.models`), garantindo que providers fora de `SUPPORTED_PROVIDERS` são removidos após o refresh; `selectable`/`supported` filtram corretamente
- `spec/models/llm/profile_spec.rb` — validações, `configured`/`active` scopes
- `spec/models/llm/profile_catalog_spec.rb` — retorna só os perfis cuja feature (`profile_fast` etc.) o account possui; serve de trava para futuras mudanças na estratégia de gate (ex.: add-ons avulsos)
- `spec/jobs/llm/model_refresh_job_spec.rb`
- Nenhum teste chama a API real dos providers nem o models.dev — sempre stub

## 12. Critérios de aceite

- [ ] `Llm::Model.selectable` nunca retorna um provider fora de `openai`/`anthropic`/`gemini`, mesmo após `refresh!` real
- [ ] O cliente (Dashboard e API) nunca vê um `Llm::Model` ou `provider`/`model_id` bruto — apenas os 4 `Llm::Profile` (`Fast`/`Balanced`/`Premium`/`Deep Reasoning`), filtrados por `Llm::ProfileCatalog`
- [ ] Trocar `llm_profiles.llm_model_id` (ex.: mover `Fast` de um provider para outro) não exige deploy nem migração, e não quebra agentes já configurados
- [ ] Chaves de API só existem via Rails credentials/env, nunca hardcoded ou versionadas
- [ ] `bin/rails llm_models:refresh` roda sem exigir mudança de código quando um novo modelo for lançado por um dos 3 providers
