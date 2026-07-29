# Plano 8 — AI Credits & Cost Engine

> Fecha o ciclo comercial descrito em [`doc/cobrancao.md`](../../cobrancao.md): toda execução de agente (Plano 3) passa a debitar **AI Credits** da `Subscription` do account, calculados a partir do custo real (`Llm::Model.pricing`, vindo do Plano 0) multiplicado pelo `credit_multiplier` do `Llm::Profile` usado (Plano 1). Depende dos Planos 0, 1 e 3.

## Objetivo

- Registrar o custo real de cada execução (`Llm::Execution`), para observabilidade/margem — nunca exposto ao cliente
- Debitar AI Credits da `Subscription` de acordo com o perfil usado
- Bloquear execução quando o account não tiver créditos suficientes
- Aplicar a isenção de custo de modelo quando o account usa BYOK (Plano 2)

## ⚠️ Decisão de produto pendente (bloqueia este plano)

A `Subscription` já implementada (`app/models/subscription.rb`, `app/models/plan.rb`) rastreia **`analyses_used`/`analyses_per_month`/`trial_analyses_*`** — um contador de unidades fixas (1 por "análise"). O modelo de `doc/cobrancao.md` precisa de um **saldo de créditos variável** (cada execução consome 1/2/5/10 créditos conforme o perfil). São conceitos incompatíveis no schema atual.

Antes de implementar este plano, decidir:

1. **Renomear** `analyses_*` → `ai_credits_*` (migração de dado, `analyses_per_month` vira `ai_credits_per_month` etc.) — mais alinhado ao novo modelo comercial, mas é uma mudança de schema em código já implementado e possivelmente já em uso (Stripe, billing UI)
2. **Adicionar campos novos** (`ai_credits_used`, `ai_credits_total`) ao lado dos existentes, aposentando `analyses_*` gradualmente
3. Reconciliar também o slug `"growth"` vs. o nome comercial "Professional" usado em `doc/cobrancao.md` (mesma pendência já registrada no Plano 0, seção 3)

Este plano assume a **opção 1** (rename) por ser mais simples de manter, mas isso deve ser confirmado antes da implementação — não é uma decisão técnica, é comercial.

## Migrations

```ruby
class RenameAnalysesToAiCreditsOnSubscriptions < ActiveRecord::Migration[8.1]
  def change
    rename_column :subscriptions, :analyses_used, :ai_credits_used
    rename_column :subscriptions, :trial_analyses_used, :trial_ai_credits_used
    rename_column :subscriptions, :trial_analyses_total, :trial_ai_credits_total
    rename_column :plans, :analyses_per_month, :ai_credits_per_month
  end
end

class CreateLlmExecutions < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_executions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true
      t.references :message, null: false, foreign_key: true
      t.references :llm_model, null: false, foreign_key: { to_table: :llm_models }
      t.references :llm_profile, null: false, foreign_key: { to_table: :llm_profiles }
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.integer :internal_cost_cents, null: false, default: 0
      t.integer :credits_charged, null: false, default: 0
      t.boolean :byok, null: false, default: false
      t.timestamps
    end

    add_index :llm_executions, :created_at
  end
end
```

## Models

`app/models/llm/execution.rb`

```ruby
class Llm::Execution < ApplicationRecord
  self.table_name = "llm_executions"

  belongs_to :account
  belongs_to :session
  belongs_to :message
  belongs_to :llm_model, class_name: "Llm::Model"
  belongs_to :llm_profile, class_name: "Llm::Profile"

  validates :credits_charged, numericality: { greater_than_or_equal_to: 0 }
end
```

Ajustes em `Subscription` (`app/models/subscription.rb`, já existente — apenas renomeia o vocabulário interno, mantendo a mesma estrutura de `trialing?`/`active?`):

```ruby
def credits_remaining
  if trialing?
    trial_ai_credits_total - trial_ai_credits_used
  elsif plan&.unlimited?
    Float::INFINITY
  else
    (plan&.ai_credits_per_month || 0) - ai_credits_used
  end
end

def can_execute?(credits)
  if trialing?
    trial_ai_credits_used + credits <= trial_ai_credits_total
  else
    active? && credits_remaining >= credits
  end
end

def charge_credits!(credits)
  raise Subscription::InsufficientCredits unless can_execute?(credits)

  if trialing?
    increment!(:trial_ai_credits_used, credits)
  else
    increment!(:ai_credits_used, credits)
  end
end
```

(`record_analysis!`/`can_analyze?`/`analyses_remaining`/`quota_percentage` existentes são renomeados na mesma migração de vocabulário — sem mudança de comportamento, só de nome.)

## Cost Engine

`app/models/llm/cost_engine.rb`

```ruby
class Llm::CostEngine
  class CreditsExhausted < StandardError; end

  INFRA_FLAT_FEE_CREDITS = 1

  def initialize(session)
    @session = session
    @account = session.account
  end

  def charge!(profile:, response:, message:)
    model = profile.llm_model
    byok = @account.llm_credentials.exists?(provider: model.provider)

    credits = byok ? INFRA_FLAT_FEE_CREDITS : credits_for(model, profile, response)
    raise CreditsExhausted unless @account.subscription.can_execute?(credits)

    Llm::Execution.create!(
      account: @account, session: @session, message: message,
      llm_model: model, llm_profile: profile, byok: byok,
      input_tokens: response.input_tokens, output_tokens: response.output_tokens,
      internal_cost_cents: internal_cost_cents(model, response), credits_charged: credits
    )

    @account.subscription.charge_credits!(credits)
  end

  private

  def internal_cost_cents(model, response)
    (
      response.input_tokens * model.input_price_per_million +
      response.output_tokens * model.output_price_per_million
    ) / 1_000_000.0 * 100
  end

  def credits_for(model, profile, response)
    (internal_cost_cents(model, response) * profile.credit_multiplier).ceil.clamp(1, Float::INFINITY)
  end
end
```

- `input_price_per_million`/`output_price_per_million` vêm de `RubyLLM::ActiveRecord::ModelMethods` (delegados de `Llm::Model#to_llm`, ver Plano 0) — nenhuma tabela de preço própria é necessária
- `credits.clamp(1, ...)` garante que toda execução cobre ao menos 1 crédito, mesmo que o custo real seja irrisório

## Integração com `Agent::Runner` (Plano 3)

```ruby
# app/models/agent/runner.rb
def respond_to(user_content)
  raise Llm::CostEngine::CreditsExhausted unless @agent.account.subscription.can_execute?(1)

  @session.messages.create!(role: :user, content: user_content)

  chat = Llm::Resolver.new(@agent).context.chat(model: @session.llm_profile.llm_model.model_id)
  chat.with_instructions(@agent.system_prompt)
  history.each { |message| chat.add_message(role: message.role, content: message.content) }

  reply = chat.ask(user_content)
  message = @session.messages.create!(role: :assistant, content: reply.content)

  Llm::CostEngine.new(@session).charge!(profile: @session.llm_profile, response: reply, message: message)
  message
end
```

A checagem `can_execute?(1)` antes de chamar o LLM é uma pré-checagem barata (evita gastar uma chamada real quando o saldo já está zerado) — a checagem definitiva (com o custo real) acontece dentro de `Llm::CostEngine#charge!`.

## Controller — bloqueio de execução

`MessagesController#create` (Plano 3) trata `Llm::CostEngine::CreditsExhausted`:

```ruby
def create
  session = current_account.sessions.find(params[:session_id])
  session.messages.create!(role: :user, content: message_params[:content])
  AgentResponseJob.perform_later(session.id, message_params[:content])

  redirect_to session
end
```

O erro estoura dentro do `AgentResponseJob` (executado em background) — capturar e transmitir via Turbo Stream:

```ruby
class AgentResponseJob < ApplicationJob
  queue_as :default

  def perform(session_id, user_content)
    session = Session.find(session_id)
    message = Agent::Runner.new(session).respond_to(user_content)

    Turbo::StreamsChannel.broadcast_append_to(session, target: "messages", partial: "messages/message", locals: { message: message })
  rescue Llm::CostEngine::CreditsExhausted
    Turbo::StreamsChannel.broadcast_append_to(session, target: "messages", partial: "messages/credits_exhausted")
  end
end
```

## Dashboard administrativo (leitura)

Reaproveita o que já existe em `billing_controller.rb` — adicionar aos dados exibidos:

- `Llm::Execution.where(account: current_account).sum(:credits_charged)` (consumo do período)
- Para o painel interno da plataforma (não do cliente): `Llm::Execution.group(:account_id).sum(:internal_cost_cents)` (margem por account) — tela administrativa separada, fora do escopo deste plano (mencionada aqui para não ser esquecida, ver `doc/cobrancao.md` §"Dashboard Administrativo")

## Testes

- `spec/models/subscription_spec.rb` — `can_execute?`/`charge_credits!`/`credits_remaining` (atualização do spec já existente para os novos nomes de coluna)
- `spec/models/llm/cost_engine_spec.rb` — cálculo de custo com pricing mockado, multiplicador aplicado corretamente, `byok: true` cobra só a taxa fixa, levanta `CreditsExhausted` quando o saldo não cobre
- `spec/models/llm/execution_spec.rb`
- `spec/jobs/agent_response_job_spec.rb` — cobre o `rescue` de `CreditsExhausted`
- Nenhum teste depende de preço real de provider — sempre stub de `Llm::Model#to_llm`/pricing

## Critérios de aceite

- [ ] Toda resposta de agente gera exatamente um `Llm::Execution`
- [ ] O custo interno real nunca é exposto ao cliente (nem na API, nem no Dashboard do cliente — só no painel administrativo)
- [ ] Trocar o modelo por trás de um perfil não muda quantos créditos uma execução consome (só muda a margem interna)
- [ ] Account com BYOK paga apenas a taxa fixa de infraestrutura, nunca o custo do modelo
- [ ] Execução é bloqueada (sem chamar o LLM) quando o saldo de créditos já está zerado
