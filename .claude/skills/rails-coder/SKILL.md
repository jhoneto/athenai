---
name: rails-coder
description: Esta skill deve ser usada quando o usuário pedir para "gerar código Rails", "criar um model", "criar um controller", "adicionar uma migration", "escrever testes Rails", "configurar background jobs", "configurar o app Rails", ou discutir convenções Rails, boas práticas, padrões ActiveRecord, Hotwire/Stimulus ou desenvolvimento Ruby on Rails no projeto Athenai.
version: 1.0.0
---

# Padrões de Geração de Código Rails

Padrões para desenvolvimento Rails assistido por IA no projeto Athenai. O código gerado deve ser tão simples e claro que lê-lo pareça ler documentação bem escrita.

## Princípios Fundamentais

1. **Seguir as convenções do Rails** — Aproveite o framework, não lute contra ele
2. **Usar a linguagem do domínio** — `Account`, `User` são as entidades centrais aqui
3. **Manter a lógica nas camadas corretas** — Models para regras de negócio, controllers para HTTP, jobs para trabalho assíncrono
4. **Escrever código legível** — O código deve ser autodocumentado, sem comentários
5. **Normalizar os dados corretamente** — Uma responsabilidade por tabela, use foreign keys e constraints

## Domínio do Athenai

| Conceito | Model |
|---------|-------|
| Empresa/tenant | `Account` |
| Pessoa com acesso | `User` (roles: `owner`, `admin`, `member`) |

## Referência Rápida

### Estrutura de Arquivos

```
app/models/              # ActiveRecord + classes com namespace
app/controllers/         # Handlers HTTP; namespace por contexto de autenticação
  api/v1/                # API externa (autenticação por API key)
  dashboard/             # Dashboard web (autenticação por sessão/Devise)
app/jobs/                # Trabalho assíncrono com ActiveJob + SolidQueue
app/forms/               # Apenas para operações multi-model
app/queries/             # Query objects complexos
app/policies/            # Autorização (ActionPolicy)
app/javascript/
  controllers/           # Stimulus controllers (Importmap)
app/views/               # Templates ERB
config/configs/          # Classes Anyway Config (variáveis de ambiente)
```

**Crítico**: Sem `app/services/`, `app/contexts/` ou `app/operations/`. Extraia operações complexas para classes com namespace no model (ex.: `User::Importer`).

### Ordem de Organização do Model

1. Gems/extensões DSL
2. Associations (com `counter_cache: true`)
3. Enums (para máquinas de estado)
4. Normalizations (Rails 7.1+)
5. Validations
6. Scopes
7. Callbacks
8. Delegations
9. Métodos públicos
10. Métodos privados

### Meta dos Controllers

5-10 linhas por action. Sem lógica de negócio. Guard clauses para retornos antecipados.

```ruby
# Exemplo de controller de API
def create
  @resource = current_account.resources.create!(resource_params)
  ResourceJob.perform_later(@resource)
  render json: @resource, status: :created
rescue ActiveRecord::RecordInvalid => e
  render json: { errors: e.record.errors }, status: :unprocessable_entity
end
```

### Stack Tecnológica

**Gems obrigatórias**: Rails 8.1, Puma, Propshaft, PostgreSQL, Hotwire (Turbo + Stimulus), Importmap, SolidQueue, SolidCache, SolidCable, Devise, RuboCop (Rails Omakase)

**Testes**: RSpec + FactoryBot + Faker

**Proibido**: CanCanCan, ActiveAdmin, gems de service object, gems de state machine, dry-types/Virtus, Sidekiq/Redis (use SolidQueue), Interactor/Trailblazer

## Referências dos Blocos de Construção

Consulte estes arquivos de referência para padrões detalhados:

| Referência | Conteúdo |
|-----------|---------|
| `references/stack.md` | Lista completa de gems, estrutura de arquivos, padrões proibidos |
| `references/models.md` | Organização de models, enums, validations, padrões de extração |
| `references/controllers.md` | Controllers enxutos, namespacing, autenticação por API key, guard clauses |
| `references/database.md` | Design de schema, constraints, indexes, migrations |
| `references/jobs.md` | SolidQueue, orquestração de workflows |
| `references/views.md` | Hotwire, Stimulus (Importmap), padrões Tailwind CSS |
| `references/forms-queries.md` | Form objects, query objects, quando usar cada um |
| `references/testing.md` | Organização RSpec, o que testar |
| `references/anti-patterns.md` | Erros comuns com alternativas, checklist de deploy |

## Fluxograma de Decisão

**Onde esta lógica deve ficar?**

- Operação em model único → Método no model
- Transação multi-model → Form object
- Chamada a API externa → Classe com namespace no model (ex.: `User::Importer`)
- Trabalho assíncrono → Job (orquestra, não executa)
- Query complexa → Query object ou scope
- Autorização → Policy (ActionPolicy)
- Configuração → Rails credentials ou variáveis de ambiente

**Quando extrair do model?**

- Método > 15 linhas → Extrair para classe com namespace
- Chama API externa → Extrair para classe com namespace
- Compartilhado entre models → Extrair para concern ou módulo

## Checklist de Geração de Código

Antes de gerar código Rails, verifique:

- [ ] Models nomeados com conceitos do domínio Athenai (Account, User)?
- [ ] Model segue a ordem de organização?
- [ ] Estados implementados como enums?
- [ ] Controllers com menos de 10 linhas por action?
- [ ] Lógica complexa extraída adequadamente?
- [ ] Banco de dados normalizado com constraints de FK?
- [ ] Counter caches nas associations has_many?
- [ ] Workflows orquestrados através de jobs?
- [ ] Variáveis de ambiente documentadas no `.kamal/secrets`?
- [ ] Testes organizados por tipo (model/request/system)?
- [ ] Todos os dados escopados ao Account (isolamento de tenant)?
