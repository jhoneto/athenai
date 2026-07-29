# Arquitetura Inicial — AI Agent Platform (Athenai)

> Baseado em [`resume_agent_platform.md`](./resume_agent_platform.md). Este documento propõe a arquitetura de domínio e de módulos para a Fase 1 (MVP), já preparando o terreno para as Fases 2 e 3, sem introduzir complexidade prematura.

---

## 1. Princípios de arquitetura

- **API First**: toda capacidade da plataforma é exposta via `Api::V1`. O Copilot Web e o Dashboard consomem a mesma API interna.
- **Multiempresa**: tudo pertence a um `Account` (já existente). Nenhum registro de agente, conector, ferramenta ou sessão existe fora de um account.
- **Multi-LLM via RubyLLM**: a plataforma nunca expõe o provedor ao cliente. O `Agent` referencia um `Llm::Profile` (`Fast`/`Balanced`/`Premium`/`Deep Reasoning`, ver seção 7), e o `RubyLLM` resolve qual chave/modelo usar por trás dele.
- **Convenções Rails**: sem `app/services`. Lógica de integração externa vira classe com namespace no model (`Connector::Adapters::Postgres`, `Tool::Executor`). Orquestração assíncrona fica em jobs.
- **Extensível, não genérico demais**: cada camada (Connector, Tool, Knowledge Base) tem contrato claro, mas o MVP implementa apenas os adapters exigidos pelo Roadmap Fase 1 (HTTP/OpenAPI, PostgreSQL, MySQL).

---

## 2. Visão geral dos módulos

```text
                         Api::V1 (REST + Swagger)
                                  │
        ┌──────────────┬─────────┼─────────┬──────────────┐
        │              │         │         │              │
    Sessions       Agents   Connectors    Tools      Knowledge Base
        │              │         │         │              │
        └──────────────┴────┬────┴─────────┴──────────────┘
                             │
                       Agent Engine
                 (planejamento, contexto,
                   tool calling via RubyLLM)
                             │
                ┌────────────┴─────────────┐
                │                           │
           Tool Engine                Knowledge Base (RAG)
        (resolve e executa                  │
         chamadas de ferramenta)      DocumentChunk (pgvector)
                │
        Connector Layer
   (adapters por tipo de sistema)
                │
   ┌─────┬──────┼───────┬────────┐
 Postgres MySQL  REST  OpenAPI  ...
```

Fluxo de uma requisição típica:

```text
Software cliente → POST /v1/sessions/:id/messages
  → Agent Engine monta contexto (system prompt + histórico + knowledge base)
  → RubyLLM chama o modelo com o catálogo de tools do agente
  → LLM decide chamar uma tool
  → Tool Engine resolve a tool → Connector Layer executa a ação
  → resultado volta para o LLM → resposta final
  → Message + ToolCall persistidos (auditoria)
  → resposta streamada/retornada ao software cliente
```

---

## 3. Domínio — novos models

Todos os models abaixo pertencem (direta ou indiretamente) a um `Account`, seguindo o isolamento de tenant já usado por `Subscription`/`Plan`.

### 3.1 Agentes e conversas

| Model | Papel |
|---|---|
| `Agent` | Definição de um agente: nome, `system_prompt`, `llm_profile` (AI Profile, seção 7), `temperature`, enum `status` (`draft`, `published`, `archived`) |
| `Agent::Permission` (ou `AgentToolScope`) | Quais tools o agente pode chamar e com quais restrições |
| `Session` | Uma conversa entre um consumidor (usuário final do software cliente) e um `Agent` |
| `Message` | Mensagem dentro de uma `Session`; enum `role` (`system`, `user`, `assistant`, `tool`); `content`; `tool_calls` (jsonb) |

```ruby
class Agent < ApplicationRecord
  belongs_to :account
  belongs_to :llm_profile, class_name: "Llm::Profile", optional: true
  has_many :agent_tools, dependent: :destroy
  has_many :tools, through: :agent_tools
  has_many :sessions, dependent: :destroy
  has_one  :knowledge_base, dependent: :destroy

  enum :status, { draft: 0, published: 1, archived: 2 }

  validates :name, presence: true
end
```

### 3.2 Conectores (detalhado na seção 4)

| Model | Papel |
|---|---|
| `Connector` | Registro lógico de uma integração (`kind`, `name`, `config` jsonb não sensível) |
| `Connector::Credential` | Segredos criptografados (Rails `encrypts`) associados a um connector |
| `Connector::Action` | Ações/capacidades descobertas ou cadastradas para um connector (ex.: uma query nomeada, um endpoint OpenAPI) |

### 3.3 Ferramentas (detalhado na seção 5)

| Model | Papel |
|---|---|
| `Tool` | Definição de uma ferramenta chamável pelo LLM (`name`, `description`, `json_schema` dos parâmetros, `kind`) |
| `AgentTool` | Join table `Agent` ↔ `Tool`, com overrides de permissão por agente |
| `ToolCall` | Log de execução: input, output, status, duração, erro — auditoria obrigatória |

### 3.4 Knowledge Base (RAG simples — Fase 1)

| Model | Papel |
|---|---|
| `KnowledgeBase` | Pertence a um `Agent` |
| `Document` | Arquivo enviado (PDF, Word, planilha) via Active Storage |
| `Document::Chunk` | Pedaço indexado do documento + embedding (`pgvector`) |

### 3.5 Acesso, catálogo de modelos e credenciais de LLM

> Ver [`doc/plans/00_ruby_llm_setup.md`](plans/00_ruby_llm_setup.md) para o detalhamento completo. O cliente **nunca** escolhe um provider/modelo diretamente — ele escolhe um **AI Profile** (`Fast`/`Balanced`/`Premium`/`Deep Reasoning`), conforme [`doc/cobrancao.md`](cobrancao.md). O modelo real por trás de cada perfil é um detalhe interno, trocável sem impacto comercial.

| Model | Papel |
|---|---|
| `ApiKey` | Chave usada pelo software cliente para autenticar na `Api::V1` (token digest, escopos, `account`) |
| `Llm::Model` | Catálogo técnico interno dos modelos disponíveis (id, provider, contexto, pricing) — alimentado pelo registro do RubyLLM, restrito a `openai`/`anthropic`/`gemini`. **Nunca exposto diretamente ao cliente** |
| `Llm::Profile` | `Fast`/`Balanced`/`Premium`/`Deep Reasoning` — a única unidade que o cliente vê. Aponta para o `Llm::Model` atualmente responsável por ele |
| `Llm::Credential` | Chave própria de LLM vinculada a um `account` (BYOK), por `provider`. Disponível apenas para accounts com a feature `byok` (plano Enterprise). Quando ausente, usa a chave da plataforma |

```ruby
class Llm::Credential < ApplicationRecord
  belongs_to :account

  enum :provider, { openai: 0, anthropic: 1, gemini: 2, openrouter: 3, vllm: 4, ollama: 5 }

  encrypts :api_key

  validates :provider, uniqueness: { scope: :account_id }
end
```

Resolução da chave em runtime (dentro do Agent Engine, não em controller) — a partir do `Llm::Model` já resolvido pelo `Llm::Profile` do agente:

```ruby
class Llm::Resolver
  def initialize(agent)
    @agent = agent
  end

  def context
    model = @agent.llm_profile.llm_model
    credential = @agent.account.llm_credentials.find_by(provider: model.provider)
    return RubyLLM if credential.blank? # usa configuração global da plataforma

    RubyLLM.context do |config|
      config.public_send("#{model.provider}_api_key=", credential.api_key)
    end
  end
end
```

Isso cumpre o requisito: **hoje usamos nossas próprias chaves, e no futuro cada account pode ter a sua**, sem mudar a Agent Engine nem a API pública. Quando há BYOK, o Cost Engine (seção 7) não cobra a parcela de custo do modelo — apenas a taxa de infraestrutura da plataforma, conforme `doc/cobrancao.md`.

---

## 4. Connector Layer (detalhado)

> "O ativo mais importante da plataforma" — precisa de um contrato estável, pois novos adapters serão adicionados continuamente (Fases 2–4).

### 4.1 Responsabilidade

O Connector Layer é a camada que sabe **como falar com um sistema externo**. Ele não sabe nada sobre LLMs, prompts ou agentes — apenas expõe **ações executáveis** de forma padronizada. O Tool Engine é o único consumidor do Connector Layer.

### 4.2 Modelo de dados

```text
Connector
├── kind: enum (postgres, mysql, sqlserver, oracle, rest, graphql, openapi,
│                gmail, microsoft365, google_drive, sharepoint, s3)
├── name, description
├── config: jsonb   # dados não sensíveis (host, porta, base_url, schema permitido)
├── status: enum (pending, connected, error, disabled)
└── belongs_to :account

Connector::Credential
├── belongs_to :connector
├── encrypts :secrets   # jsonb criptografado: senha, api_key, oauth tokens
└── expires_at (para OAuth)

Connector::Action
├── belongs_to :connector
├── name, description
├── input_schema: jsonb   # JSON Schema dos parâmetros aceitos
├── kind: enum (query, http_call, graphql_call, file_search, ...)
└── definition: jsonb     # a query SQL parametrizada, o path+método REST, a operação GraphQL etc.
```

Um `Connector` sozinho não é chamável — ele apenas representa a conexão. Quem é chamável é a `Connector::Action`. Isso separa "como conectar" de "o que posso fazer", permitindo que uma `Connector::Action` seja promovida a `Tool` (seção 5.3).

### 4.3 Contrato do Adapter

Cada tipo de connector implementa uma interface comum em `app/models/connector/adapters/`:

```ruby
module Connector::Adapters
  class Base
    def initialize(connector)
      @connector = connector
      @credential = connector.credential
    end

    # Contrato que todo adapter deve implementar
    def test_connection! = raise NotImplementedError
    def call(action, params) = raise NotImplementedError
  end
end
```

Adapters da Fase 1:

| Adapter | Estratégia |
|---|---|
| `Connector::Adapters::Postgres` / `::Mysql` | Conexão via `ActiveRecord::Base.establish_connection` isolada (connection handler próprio, nunca a conexão principal da app). Executa **apenas** `Connector::Action#definition` pré-cadastradas — nunca SQL livre vindo do LLM. Modo somente leitura reforçado por role de banco (`readonly_user`) quando possível |
| `Connector::Adapters::Http` | Usa `Faraday` (ou `Net::HTTP` puro) para chamar endpoints REST cadastrados manualmente como `Connector::Action` |
| `Connector::Adapters::OpenApi` | Importa uma spec OpenAPI (`config[:spec_url]`), gera uma `Connector::Action` por operação automaticamente (`Connector::OpenApiImporter`) |

Adapters futuros (Fase 3) seguem o mesmo contrato: `Connector::Adapters::Gmail`, `::Microsoft365`, `::S3`, `::Sap`, etc. — cada um resolve autenticação (OAuth, API key, IAM) dentro de si mesmo, sem vazar detalhes para o Tool Engine.

### 4.4 Ciclo de vida de um Connector

1. Cliente cria o connector via `POST /v1/connectors` informando `kind` + credenciais
2. `Connector::CredentialEncryptorJob` não é necessário — `encrypts` já criptografa de forma síncrona; um job (`Connector::TestConnectionJob`) valida a conexão e atualiza `status`
3. Para REST/OpenAPI, o cliente cadastra `Connector::Action` manualmente ou importa uma spec (`Connector::OpenApiImporter`)
4. Para bancos de dados, o cliente cadastra `Connector::Action` como queries nomeadas e parametrizadas (nunca SQL dinâmico gerado pelo LLM)
5. Ações ficam disponíveis para virar `Tool`

### 4.5 Segurança

- Segredos sempre em `Connector::Credential` com `encrypts`, nunca em `config`
- Banco de dados: allowlist de `Connector::Action`, timeout de query, `LIMIT` obrigatório injetado pelo adapter, sem DDL/DML permitido (somente `SELECT`)
- HTTP/OpenAPI: allowlist de domínios (`config[:base_url]`), timeout, tamanho máximo de resposta
- Toda chamada de `Connector::Action` é registrada (via `ToolCall`, seção 5.4) — auditoria fim a fim

---

## 5. Tool Engine (detalhado)

> Camada que transforma capacidades (nativas ou de conectores) em **funções chamáveis pelo LLM**, e executa essas chamadas com segurança e observabilidade.

### 5.1 O que é uma Tool

Uma `Tool` é a unidade que o LLM enxerga via *function calling* do RubyLLM. Ela tem:

- `name` — identificador estável (`consultar_cliente`, `gerar_boleto`)
- `description` — usada pelo LLM para decidir quando chamar
- `input_schema` (jsonb) — JSON Schema dos parâmetros, no formato que o RubyLLM espera para declarar tools
- `kind`: enum `{ connector: 0, native: 1, webhook: 2 }`

```ruby
class Tool < ApplicationRecord
  belongs_to :account
  belongs_to :connector_action, class_name: "Connector::Action", optional: true
  has_many :agent_tools, dependent: :destroy
  has_many :agents, through: :agent_tools
  has_many :tool_calls, dependent: :destroy

  enum :kind, { connector: 0, native: 1, webhook: 2 }

  validates :name, uniqueness: { scope: :account_id }
  validates :input_schema, presence: true
end
```

### 5.2 Tipos de Tool

| Kind | Origem | Exemplo |
|---|---|---|
| `connector` | Envolve uma `Connector::Action` existente | "Consultar pedido" → executa uma query Postgres nomeada |
| `native` | Implementada em Ruby, dentro da própria plataforma | Calculadora, busca na Knowledge Base (`Tool::Native::KnowledgeSearch`) |
| `webhook` | Chama uma URL do software cliente (callback) | "Atualizar CRM" → dispara webhook assinado (HMAC) para o sistema do cliente |

Tools nativas ficam em `app/models/tool/native/*.rb`, cada uma implementando `#call(params)` e registrada num registry simples (`Tool::Native::REGISTRY`), sem necessidade de gem de plugin.

### 5.3 Promovendo uma Connector::Action a Tool

Como Connector e Tool são desacoplados, criar uma tool a partir de uma ação de conector é uma operação explícita (não automática), para o cliente controlar o que o LLM pode ver:

```ruby
class Tool::PromoteFromConnectorAction
  def self.call(connector_action:, name:, description:)
    Tool.create!(
      account: connector_action.connector.account,
      kind: :connector,
      connector_action: connector_action,
      name: name,
      description: description,
      input_schema: connector_action.input_schema
    )
  end
end
```

(Extraído como classe com namespace por envolver mais de um model — regra do fluxograma de decisão da skill.)

### 5.4 Execução — `Tool::Executor`

O Tool Engine tem um único ponto de entrada, chamado pelo Agent Engine quando o LLM solicita uma tool call:

```ruby
class Tool::Executor
  class PermissionDenied < StandardError; end

  def initialize(agent:, tool:, params:)
    @agent, @tool, @params = agent, tool, params
  end

  def call
    authorize!

    tool_call = ToolCall.create!(agent: @agent, tool: @tool, input: @params, status: :running)

    result = case @tool.kind
    when "connector" then run_connector
    when "native"    then Tool::Native::REGISTRY.fetch(@tool.name).call(@params)
    when "webhook"   then Tool::WebhookInvoker.new(@tool, @params).call
    end

    tool_call.update!(status: :succeeded, output: result)
    result
  rescue => e
    tool_call&.update!(status: :failed, error: e.message)
    raise
  end

  private

  def authorize!
    raise PermissionDenied unless @agent.tools.exists?(@tool.id)
  end

  def run_connector
    connector = @tool.connector_action.connector
    adapter_for(connector).call(@tool.connector_action, @params)
  end

  def adapter_for(connector)
    "Connector::Adapters::#{connector.kind.camelize}".constantize.new(connector)
  end
end
```

Pontos importantes:

- **Autorização por agente**: mesmo que a tool exista no account, só é executável se estiver associada ao `Agent` via `AgentTool` — implementa o requisito de Security do documento original (agente Financeiro não pode "Alterar pedidos")
- **Timeout**: tools de conector/webhook rodam com `Timeout` (ou `Faraday` timeout) — nunca bloqueiam a resposta ao LLM indefinidamente
- **Chamadas potencialmente lentas** (webhook, importações grandes) podem ser assíncronas: `Tool::Executor` enfileira via `ToolCallJob` e o Agent Engine faz *polling*/streaming do resultado, mantendo a mesma interface pública
- **Auditoria obrigatória**: todo `ToolCall` fica persistido com input/output/erro — atende "Auditoria" e "Histórico" do documento original

### 5.5 Catálogo de Tools por Agente

`AgentTool` permite overrides por agente sem duplicar a `Tool`:

```ruby
class AgentTool < ApplicationRecord
  belongs_to :agent
  belongs_to :tool

  # overrides opcionais: limite de chamadas, params fixos (ex.: filtrar por filial)
  store_accessor :constraints, :max_calls_per_session, :fixed_params
end
```

Isso permite que dois agentes diferentes compartilhem a mesma `Tool` "Consultar Cliente", mas um agente Financeiro só possa consultar (constraints somente leitura) enquanto outro agente Comercial tenha mais parâmetros liberados.

---

## 6. Agent Engine (visão de integração com o RubyLLM)

Não é o foco deste documento, mas para contextualizar como Connector Layer e Tool Engine se conectam a ele:

```ruby
class Agent::Runner
  def initialize(session)
    @session = session
    @agent = session.agent
  end

  def respond(user_message)
    @session.messages.create!(role: :user, content: user_message)

    model = @agent.llm_profile.llm_model
    chat = Llm::Resolver.new(@agent).context.chat(model: model.model_id)
    chat.with_tools(*tool_definitions)
    chat.with_instructions(@agent.system_prompt)

    response = chat.ask(user_message) do |tool_call|
      Tool::Executor.new(agent: @agent, tool: tool_call.tool, params: tool_call.params).call
    end

    message = @session.messages.create!(role: :assistant, content: response.content, tool_calls: response.tool_calls)
    Llm::CostEngine.new(@session).charge!(profile: @agent.llm_profile, response: response, message: message)
  end

  private

  def tool_definitions
    @agent.tools.map { |tool| Tool::RubyLlmDefinition.new(tool).to_h }
  end
end
```

`Tool::RubyLlmDefinition` converte `Tool#input_schema` para o formato de tool que o RubyLLM espera — isolando o resto da plataforma do formato específico da gem.

---

## 7. Cobrança — AI Profiles & Cost Engine

> Baseado em [`doc/cobrancao.md`](cobrancao.md). Resolve a decisão que ficava em aberto no Plano 0 sobre como o modelo é exposto: **o cliente nunca escolhe um provider/modelo — ele escolhe um AI Profile, e paga em AI Credits**.

### 7.1 AI Profiles

| Profile | Multiplicador | Quem tem acesso (feature) |
|---|---|---|
| `Fast` | 1x | todos os planos |
| `Balanced` | 2x | Professional, Enterprise |
| `Premium` | 5x | Professional, Enterprise |
| `Deep Reasoning` | 10x | Enterprise |

```ruby
class Llm::Profile < ApplicationRecord
  belongs_to :llm_model, optional: true   # modelo real por trás do perfil, trocável sem aviso ao cliente

  enum :key, { fast: 0, balanced: 1, premium: 2, deep_reasoning: 3 }

  validates :credit_multiplier, numericality: { greater_than: 0 }
end
```

`Agent` referencia um `Llm::Profile` (não um `Llm::Model` diretamente — ver `doc/plans/00_ruby_llm_setup.md`). Trocar o modelo por trás de um perfil (ex.: `Fast` de `gpt-5-mini` para `gemini-flash`) é uma operação puramente administrativa, invisível ao cliente e aos agentes já configurados.

### 7.2 Gate por plano — `Llm::ProfileCatalog`

Reaproveita o mecanismo já existente em `Plan::FEATURES` (`app/models/plan.rb`), adicionando entradas por perfil (`profile_fast`, `profile_balanced`, `profile_premium`, `profile_deep_reasoning`) e `byok`:

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

Este é o único ponto de decisão que o Dashboard/API consulta para montar a lista de perfis disponíveis para um `Agent` — nenhum controller ou view lê `Llm::Profile`/`Llm::Model` diretamente.

### 7.3 Cost Engine

Toda execução de agente gera um custo interno real (tokens de entrada/saída, embeddings, RAG, OCR), calculado a partir do `pricing` já presente em `Llm::Model` (vindo do registro do RubyLLM). Esse custo:

- **nunca é exibido ao cliente**
- é convertido em **AI Credits** aplicando o multiplicador do `Llm::Profile` usado
- é debitado da `Subscription` do account, e registrado como `Llm::Execution` para auditoria/margem

```ruby
class Llm::CostEngine
  def initialize(session)
    @session = session
    @account = session.account
  end

  def charge!(profile:, response:, message:)
    internal_cost_cents = cost_for(profile.llm_model, response)
    credits = (internal_cost_cents * profile.credit_multiplier / BASE_CENTS_PER_CREDIT).ceil
    credits = INFRA_FLAT_FEE_CREDITS if byok?(profile.llm_model)

    Llm::Execution.create!(
      session: @session, message: message, llm_model: profile.llm_model, llm_profile: profile,
      input_tokens: response.input_tokens, output_tokens: response.output_tokens,
      internal_cost_cents: internal_cost_cents, credits_charged: credits
    )

    @account.subscription.charge_credits!(credits)
  end

  private

  def byok?(model)
    @account.llm_credentials.exists?(provider: model.provider)
  end
end
```

> **Nota de implementação**: a `Subscription` já existente (`app/models/subscription.rb`) hoje rastreia `analyses_used`/`analyses_per_month` (contador fixo de 1 por execução). O modelo de `doc/cobrancao.md` exige um saldo de **créditos variáveis** (`ai_credits_used`/`ai_credits_total`, com custo diferente por perfil). Essa migração de dado (`analyses_*` → `ai_credits_*`) é uma decisão de produto/banco que ainda precisa ser feita explicitamente antes do Cost Engine entrar em produção — ver `doc/plans/fase1/08_ai_credits_cost_engine.md` para o plano de migração.

### 7.4 BYOK (Bring Your Own Key)

Quando o account tem `Llm::Credential` para o provider do modelo em uso (feature `byok`, hoje só Enterprise), o Cost Engine cobra apenas uma taxa fixa de infraestrutura (`INFRA_FLAT_FEE_CREDITS`) em vez do custo real do modelo — o custo do modelo em si passa a ser responsabilidade do cliente junto ao provider, conforme `doc/cobrancao.md`.

---

## 8. API (não segue o padrão OpenAI)

Endpoints representam conceitos da plataforma, não `/responses`/`/completions`:

```
POST   /v1/agents
GET    /v1/agents/:id
POST   /v1/sessions
POST   /v1/sessions/:id/messages       # cria mensagem, pode responder via streaming (SSE)
POST   /v1/connectors
POST   /v1/connectors/:id/actions
POST   /v1/connectors/:id/test
POST   /v1/tools
POST   /v1/tools/from_connector_action
GET    /v1/tool_calls                  # auditoria
```

- Autenticação: `ApiKey` (header `Authorization: Bearer ath_live_...`), resolvida para o `Account`
- Documentação: gem `rswag` (`rswag-api` + `rswag-ui`) gerando Swagger/OpenAPI a partir das specs de request do RSpec — a mesma spec que testa a API vira a fonte da documentação, sem duplicar esforço
- Página de docs publicada em `/api-docs`, versionada por `v1`

---

## 9. Estrutura de arquivos proposta

```
app/models/
  account.rb, user.rb                      # existentes
  agent.rb
  agent_tool.rb
  session.rb
  message.rb
  connector.rb
  connector/
    credential.rb
    action.rb
    adapters/
      base.rb
      postgres.rb
      mysql.rb
      http.rb
      open_api.rb
    open_api_importer.rb
  tool.rb
  tool/
    executor.rb
    promote_from_connector_action.rb
    webhook_invoker.rb
    ruby_llm_definition.rb
    native/
      registry.rb
      knowledge_search.rb
  tool_call.rb
  knowledge_base.rb
  document.rb
  document/
    chunk.rb
  api_key.rb
  llm/
    model.rb
    profile.rb
    profile_catalog.rb
    credential.rb
    resolver.rb
    cost_engine.rb
    execution.rb

app/controllers/api/v1/
  agents_controller.rb
  sessions_controller.rb
  messages_controller.rb
  connectors_controller.rb
  connector_actions_controller.rb
  tools_controller.rb
  tool_calls_controller.rb

app/jobs/
  connector/test_connection_job.rb
  tool_call_job.rb
  document_index_job.rb
```

---

## 10. Mapeamento com o Roadmap

| Fase 1 (MVP) | Componente entregue |
|---|---|
| Cadastro de agentes, seleção de modelo | `Agent`, `Llm::Model`, `Llm::Profile`, `Llm::ProfileCatalog`, `Llm::Credential`, `Llm::Resolver` |
| Chat Web, Histórico, Sessions | `Session`, `Message`, `Agent::Runner` |
| Cobrança em AI Credits | `Llm::CostEngine`, `Llm::Execution` (ver seção 7 e `doc/plans/fase1/08_ai_credits_cost_engine.md`) |
| Upload de documentos, RAG simples | `KnowledgeBase`, `Document`, `Document::Chunk` |
| Conector HTTP (OpenAPI), PostgreSQL, MySQL | `Connector`, `Connector::Action`, adapters `Http`/`OpenApi`/`Postgres`/`Mysql` |
| API REST | `Api::V1::*Controller` + `rswag` |

| Fase 2 (Beta) | Componente entregue |
|---|---|
| Controle de permissões | `AgentTool#constraints`, `Tool::Executor#authorize!` |
| Tool Calling, Catálogo de ferramentas | `Tool`, `AgentTool`, `Tool::RubyLlmDefinition` |
| Logs, Auditoria | `ToolCall` |
| Streaming | SSE em `Api::V1::MessagesController` |
| Webhooks | `kind: :webhook` em `Tool`, `Tool::WebhookInvoker` |

As Fases 3–5 (novos adapters de conector, marketplace, produtos verticais) reaproveitam o mesmo contrato de `Connector::Adapters::Base` e `Tool`, sem exigir mudança estrutural.
