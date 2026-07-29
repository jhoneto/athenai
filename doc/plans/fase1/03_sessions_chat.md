# Plano 3 — Sessions, Messages & Chat Web

> Primeira entrega demonstrável: o Copilot Web conversa de fato com um `Agent`, usando `RubyLLM` através do `Llm::Resolver` (Plano 2). Sem tools ainda (isso é Fase 2/Planos 5-6 na parte de execução) — aqui o agente responde só com o `system_prompt` e o histórico da sessão.
>
> **Atualizado por [`00_ruby_llm_setup.md`](../00_ruby_llm_setup.md)** e por [`doc/cobrancao.md`](../../cobrancao.md): `Session` guarda `llm_profile_id` (snapshot do **perfil de IA**, não do modelo bruto — copiado de `agent.llm_profile_id` na criação) para que trocar o perfil do agente não altere conversas já existentes. O modelo real é sempre resolvido em runtime a partir do perfil (`session.llm_profile.llm_model`), nunca fixado na sessão.

## Objetivo

- `Session` = uma conversa entre um usuário e um `Agent`
- `Message` = cada turno da conversa
- Interface de chat via Hotwire (Turbo Streams), sem reload de página
- Endpoint de resposta pode ser síncrono no MVP; estrutura já preparada para streaming (Fase 2)

## Migrations

```ruby
class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true
      t.references :llm_profile, null: false, foreign_key: { to_table: :llm_profiles }
      t.references :user, null: false, foreign_key: true   # quem iniciou a conversa no dashboard
      t.string :title
      t.integer :status, null: false, default: 0
      t.timestamps
    end
  end
end

class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :session, null: false, foreign_key: true
      t.integer :role, null: false
      t.text    :content, null: false
      t.jsonb   :tool_calls, null: false, default: []
      t.timestamps
    end

    add_index :messages, [ :session_id, :created_at ]
  end
end
```

`role` como enum evita string solta; `tool_calls` já existe no schema desde já para não exigir migration extra no Plano 6, mesmo que fique vazio até lá.

## Models

`app/models/session.rb`

```ruby
class Session < ApplicationRecord
  belongs_to :account
  belongs_to :agent
  belongs_to :llm_profile, class_name: "Llm::Profile"
  belongs_to :user
  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  enum :status, { open: 0, closed: 1 }

  validates :agent_id, presence: true

  before_validation :copy_llm_profile_from_agent, on: :create

  def title_or_default
    title.presence || "Conversa #{created_at.to_date}"
  end

  private

  def copy_llm_profile_from_agent
    self.llm_profile_id ||= agent&.llm_profile_id
  end
end
```

`app/models/message.rb`

```ruby
class Message < ApplicationRecord
  belongs_to :session

  enum :role, { system: 0, user: 1, assistant: 2, tool: 3 }

  validates :content, presence: true, unless: :tool?
end
```

Associações reversas:

```ruby
# Account
has_many :sessions, dependent: :destroy

# Agent
has_many :sessions, dependent: :destroy
```

## Orquestração — `Agent::Runner`

Extraído para namespace por chamar API externa (RubyLLM) — regra do fluxograma de decisão da skill.

`app/models/agent/runner.rb`

```ruby
class Agent::Runner
  def initialize(session)
    @session = session
    @agent = session.agent
  end

  def respond_to(user_content)
    @session.messages.create!(role: :user, content: user_content)

    chat = Llm::Resolver.new(@agent).context.chat(model: @session.llm_profile.llm_model.model_id)
    chat.with_instructions(@agent.system_prompt)
    history.each { |message| chat.add_message(role: message.role, content: message.content) }

    reply = chat.ask(user_content)

    @session.messages.create!(role: :assistant, content: reply.content)
  end

  private

  def history
    @session.messages.where(role: %i[user assistant]).order(:created_at)
  end
end
```

**Nota**: este plano ainda não debita AI Credits — a integração com o Cost Engine (`Llm::CostEngine.new(@session).charge!(...)`, ver `doc/architecture.md` §7.3) entra em [`fase1/08_ai_credits_cost_engine.md`](08_ai_credits_cost_engine.md), que estende exatamente este `Agent::Runner#respond_to`.

## Job (assincronia da resposta)

`app/jobs/agent_response_job.rb`

```ruby
class AgentResponseJob < ApplicationJob
  queue_as :default

  def perform(session_id, user_content)
    session = Session.find(session_id)
    message = Agent::Runner.new(session).respond_to(user_content)

    Turbo::StreamsChannel.broadcast_append_to(
      session, target: "messages", partial: "messages/message", locals: { message: message }
    )
  end
end
```

A resposta roda em background e é entregue via Turbo Stream — a UI não trava esperando o LLM.

## Controllers (Dashboard)

`app/controllers/sessions_controller.rb`

```ruby
class SessionsController < ApplicationController
  def index
    @sessions = current_account.sessions.includes(:agent).order(created_at: :desc)
  end

  def show
    @session = current_account.sessions.find(params[:id])
  end

  def create
    @session = current_account.sessions.create!(agent_id: params[:agent_id], user: current_user)
    redirect_to @session
  end

  def destroy
    current_account.sessions.find(params[:id]).destroy
    redirect_to sessions_path
  end
end
```

`app/controllers/messages_controller.rb`

```ruby
class MessagesController < ApplicationController
  def create
    session = current_account.sessions.find(params[:session_id])
    session.messages.create!(role: :user, content: message_params[:content])
    AgentResponseJob.perform_later(session.id, message_params[:content])

    redirect_to session
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
```

Nota: a mensagem do usuário já é criada no controller (para aparecer imediatamente na tela via Turbo Stream do próprio `create.turbo_stream.erb`), e o job cuida apenas da resposta do assistente — evita duplicar a criação da mensagem de usuário dentro do `Agent::Runner`. Ajustar `Agent::Runner#respond_to` para não recriar a mensagem de usuário quando chamado pelo job (receber `Message` já persistida, não o texto bruto) — ver nota de implementação abaixo.

**Nota de implementação**: o `Agent::Runner` do job deve receber a sessão já com a mensagem de usuário persistida e apenas gerar a resposta do assistente, evitando duplicidade com o `MessagesController#create`. Ajustar a assinatura para `Agent::Runner.new(session).respond!` (sem argumento), lendo a última mensagem `user` pendente de resposta.

## Rotas

```ruby
resources :sessions, only: %i[index show create destroy] do
  resources :messages, only: :create
end
```

## Views

- `app/views/sessions/index.html.erb` — lista de conversas + botão "Nova conversa" com select de agente publicado
- `app/views/sessions/show.html.erb` — `turbo_stream_from @session`, lista de mensagens (`#messages`), formulário de envio
- `app/views/messages/_message.html.erb` — bolha de chat estilizada por `role` (Tailwind)
- `app/views/messages/create.turbo_stream.erb` — append da mensagem do usuário imediatamente
- Stimulus controller `chat_controller.js` — limpa o textarea após submit, auto-scroll para a última mensagem

## Testes

- `spec/factories/sessions.rb`, `spec/factories/messages.rb`
- `spec/models/session_spec.rb` — cobre `copy_llm_profile_from_agent` (sessão criada sem `llm_profile_id` explícito herda o do agente)
- `spec/models/message_spec.rb`
- `spec/models/agent/runner_spec.rb` — mocka `Llm::Resolver`/`RubyLLM` (não bate em API real), garante que a mensagem do assistente é persistida com o conteúdo retornado
- `spec/jobs/agent_response_job_spec.rb`
- `spec/requests/sessions_spec.rb`, `spec/requests/messages_spec.rb` — isolamento por account, criação de sessão só com agente `published`

## Critérios de aceite

- [ ] Usuário consegue iniciar uma conversa com um agente publicado
- [ ] Histórico persiste e é reenviado como contexto a cada novo turno
- [ ] Resposta do LLM chega via Turbo Stream, sem reload
- [ ] Nenhuma chamada real a LLM externo acontece nos testes (mock/stub)
