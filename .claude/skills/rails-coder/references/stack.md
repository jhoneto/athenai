# Stack Tecnológica & Estrutura de Arquivos

## Gems Instaladas (atual)

### Framework Principal
- **Rails 8.1** — Framework principal
- **Puma** — Web server (com Thruster para cache de assets em produção)
- **Propshaft** — Asset pipeline (não Sprockets)

### Banco de Dados
- **PostgreSQL** — Banco principal
- **ActiveRecord** — ORM (built-in)

### Frontend
- **Hotwire** — Turbo + Stimulus para interatividade
- **Importmap** — Módulos ES sem build step Node.js
- **Tailwind CSS** (`tailwindcss-rails`) — v4, configurado via CSS `@theme`

### Background Jobs / Cache / WebSocket
- **SolidQueue** — Job backend (padrão Rails 8, sem Redis)
- **SolidCache** — Cache database-backed
- **SolidCable** — Action Cable database-backed

### Autenticação & Autorização
- **Devise** — Autenticação de usuários (login, cadastro, recuperação de senha)

### Testes
- **RSpec** + FactoryBot + Faker — Framework de testes
- **Shoulda Matchers** — Matchers para validações e associations

### Qualidade de Código
- **RuboCop** (`rubocop-rails-omakase`) — Linter no estilo padrão Rails
- **Brakeman** — Scan de segurança
- **Bundler-audit** — Scan de vulnerabilidades em gems

### Implantação
- **Kamal** — Deploy Docker-first
- **Docker** — Container de produção

## Gems Recomendadas (ainda não instaladas)

| Gem | Finalidade |
|-----|-----------|
| **ActionPolicy** | Autorização por role (owner/admin/member) |
| **HTTParty** ou **Faraday** | Cliente HTTP para APIs externas |
| **Nanoid** | IDs curtos únicos para recursos de API |
| **rails-i18n** | Internacionalização |

## Gems Proibidas

**Nunca usar:**

| Proibido | Por quê | Alternativa |
|----------|---------|-------------|
| Sidekiq / Redis | Dependência externa desnecessária | SolidQueue (já instalado) |
| CanCanCan | Padrões desatualizados | ActionPolicy |
| ActiveAdmin | Pesado e inflexível | Dashboard customizado com Hotwire |
| Pundit | Menos flexível | ActionPolicy |
| Service object gems | Abstração desnecessária | Namespaced model classes |
| AASM/state_machine | Dependência externa | Enums built-in |
| Virtus/dry-types | Over-typed | Plain Ruby, ActiveModel |
| Interactor/Trailblazer | Context objects | Jobs + métodos no model |
| Vite Rails | Não usado neste projeto | Importmap (já instalado) |

> **Nota**: Devise É USADO neste projeto para autenticação de usuários no dashboard.

## Estrutura de Arquivos

```
app/
├── models/
│   ├── application_record.rb
│   ├── account.rb                  # Tenant principal
│   ├── user.rb                     # Com role: owner/admin/member
│   └── account_user.rb             # Join table com roles
├── controllers/
│   ├── application_controller.rb
│   ├── users/
│   │   └── registrations_controller.rb  # Cadastro customizado
│   ├── api/
│   │   └── v1/
│   │       └── application_controller.rb
│   └── dashboard/
│       └── application_controller.rb    # Autenticação via Devise
├── jobs/
│   └── application_job.rb
├── forms/                          # Apenas multi-model
│   └── application_form.rb
├── queries/                        # Query objects complexos
│   └── application_query.rb
├── policies/                       # ActionPolicy
│   └── application_policy.rb
├── views/
│   ├── layouts/
│   │   ├── application.html.erb    # Layout principal (sidebar + topbar futuramente)
│   │   └── auth.html.erb           # Layout de autenticação
│   ├── users/
│   │   └── registrations/
│   │       └── new.html.erb        # Formulário de cadastro
│   └── devise/
│       └── sessions/
│           └── new.html.erb        # Formulário de login
├── javascript/
│   ├── application.js              # Entry point Importmap
│   └── controllers/                # Stimulus controllers
│       ├── application.js
│       └── index.js
├── assets/
│   ├── tailwind/
│   │   └── application.css         # @theme com tokens da marca
│   └── stylesheets/
│       └── application.css
└── mailers/

config/
├── queue.yml                       # SolidQueue
├── cable.yml                       # SolidCable
├── cache.yml                       # SolidCache
└── recurring.yml                   # Jobs agendados

spec/
├── models/
├── requests/
├── system/
├── factories/
└── support/
```

## Regras Críticas

### Sem Diretórios de Serviço

**Nunca criar:**
- `app/services/`
- `app/contexts/`
- `app/operations/`
- `app/interactors/`
- `app/use_cases/`

**Em vez disso:**
- Operações simples → Métodos no model
- Operações complexas → Namespaced model classes
- Transações multi-model → Form objects (`app/forms/`)
- Operações assíncronas → Jobs (`app/jobs/`)

### Namespaced Model Classes

Quando a lógica do model cresce ou chama APIs externas:

```ruby
# app/models/user/importer.rb
class User::Importer
  def initialize(account, csv_data)
    @account = account
    @csv_data = csv_data
  end

  def call
    # lógica de importação
  end

  private

  attr_reader :account, :csv_data
end

# Uso no job:
User::Importer.new(account, csv_data).call
```

### Namespacing de Controllers

Namespace por contexto de autenticação:

```ruby
# Dashboard web: autenticação via Devise
# app/controllers/dashboard/application_controller.rb
class Dashboard::ApplicationController < ApplicationController
  before_action :authenticate_user!  # Devise helper

  private

  def current_account
    @current_account ||= current_user.accounts.first
  end
  helper_method :current_account
end
```

### Variáveis de Ambiente

Usar `ENV["VAR"]` ou Rails credentials para configurações sensíveis. Documentar variáveis necessárias no `.kamal/secrets`.
