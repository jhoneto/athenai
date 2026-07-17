# Anti-Padrões & Checklist

## Anti-Padrões Comuns

### Anti-Padrões de Arquitetura

| Anti-Padrão | Problema | Alternativa |
|--------------|---------|-------------|
| Service objects | Camada de abstração desnecessária | Namespaced model classes ou jobs |
| Result/Response objects | Over-engineering | Valores de retorno + exceções |
| Context objects | Dependências ocultas | Parâmetros explícitos |
| Interactors/Use cases | Overhead do framework | Classes Ruby simples |
| Concerns para lógica de negócio | Complexidade escondida | Herança ou delegação |

### Anti-Padrões de Organização de Código

| Anti-Padrão | Problema | Alternativa |
|--------------|---------|-------------|
| Diretório `app/services/` | Gaveta de entulho | Namespaced model classes |
| Diretório `app/contexts/` | Propósito obscuro | Form objects ou jobs |
| Diretório `app/operations/` | Duplicação de jobs | Jobs |
| Passar hashes por aí | Sem tipos, propenso a erros | Retornar objetos reais |
| God objects | Responsabilidades demais | Extrair para classes focadas |

### Anti-Padrões de Controller

| Anti-Padrão | Problema | Alternativa |
|--------------|---------|-------------|
| Fat controllers | Vazamento de lógica de negócio | Extrair para models/jobs |
| Before_actions complexos | Fluxo oculto | Verificações explícitas nas actions |
| Concerns para lógica de negócio | Código espalhado | Herança de base controller |
| Blocos rescue em todo lugar | Tratamento inconsistente | `rescue_from` no ApplicationController |
| Falta de escopo por tenant | Vazamento de dados entre accounts | Sempre escopar ao `current_account` |

### Anti-Padrões de Model

| Anti-Padrão | Problema | Alternativa |
|--------------|---------|-------------|
| Cadeias de callbacks | Difícil de acompanhar | Chamadas de método explícitas |
| Fat models | Responsabilidades demais | Extrair para classes com namespace |
| Default scopes | Comportamento surpreendente | Named scopes |
| Method missing magic | Difícil de depurar | Métodos explícitos |
| Falta de escopo por account_id | Vazamento de dados multi-tenant | Sempre escopar queries ao account |

### Anti-Padrões de View

| Anti-Padrão | Problema | Alternativa |
|--------------|---------|-------------|
| Lógica complexa nas views | Difícil de testar | Query objects |
| Queries N+1 em loops | Performance ruim | Eager loading no controller |
| JavaScript inline | Difícil de manter | Stimulus controllers |
| Partials profundamente aninhados | Difícil de rastrear | Estrutura plana de partials |

### Anti-Padrões de Banco de Dados

| Anti-Padrão | Problema | Alternativa |
|--------------|---------|-------------|
| Foreign keys sem constraints | Integridade de dados comprometida | Sempre adicionar constraints FK |
| Booleans nullable | Lógica de três estados | NOT NULL com default |
| Sem indexes em FKs | Joins lentos | Indexar todas as foreign keys |
| Dados desnormalizados | Risco de dados desatualizados | Normalizar, usar counter cache |
| String para enums | Sem validação | Tipo enum do PostgreSQL |
| Sem index em account_id | Queries lentas por tenant | Indexar account_id em todas as tabelas principais |

## Exemplos Detalhados

### Service Objects para Namespaced Classes

```ruby
# Ruim — service object
# app/services/user_onboarding.rb
class UserOnboarding
  def call(user)
    # ...
  end
end

# Bom — namespaced model class
# app/models/user/onboarding.rb
class User::Onboarding
  def initialize(user)
    @user = user
  end

  def call
    # ...
  end
end
```

### Falta de Escopo por Tenant

```ruby
# Ruim — qualquer account pode acessar qualquer recurso
def show
  @resource = Resource.find(params[:id])
end

# Bom — escopo ao account atual
def show
  @resource = current_account.resources.find(params[:id])
end
```

### Result Objects para Retornos Simples

```ruby
# Ruim — result object
class ProcessUser
  def call(user)
    result = process(user)
    Result.new(success: true, data: result)
  rescue => e
    Result.new(success: false, error: e.message)
  end
end

# Bom — retorno simples + exceção
class User::Processor
  def call
    process(@user)  # Retorna o usuário processado
  end
  # Deixar exceções propagarem naturalmente
end
```

## Guia de Estilo de Código

### Nomenclatura (Domínio Athenai)

```ruby
# Models: Substantivos singulares, linguagem do domínio
class Account < ApplicationRecord     # Não: Company, Tenant, Organization
class User < ApplicationRecord        # Papel por Account via role
class AccountUser < ApplicationRecord # Join table com role

# Controllers: Plural, com namespace por contexto
class Users::RegistrationsController
class Dashboard::UsersController
class Dashboard::AccountsController

# Jobs: Verbo + substantivo + Job
class WelcomeEmailJob
class DailyReportJob
class BulkImportJob

# Namespaced classes: Model::Operação
class User::Importer
class User::Onboarding
class Account::Setup
```

### Comprimento de Métodos

- Actions de controller: máximo 5-10 linhas
- Métodos de model: máximo 15 linhas (extrair se maior)
- Métodos privados: manter focados, responsabilidade única

### Guard Clauses

```ruby
# Bom — retornos antecipados
def process
  return if already_processed?
  return unless valid_for_processing?

  do_processing
end

# Ruim — condicionais aninhados
def process
  if !already_processed?
    if valid_for_processing?
      do_processing
    end
  end
end
```

## Checklist de Deploy

Antes de fazer deploy do código Rails, verifique:

### Nomenclatura & Domínio
- [ ] Models nomeados com conceitos do domínio Athenai (Account, User)?
- [ ] Usando `Account` em vez de `Company` / `Tenant`?
- [ ] Nenhum nome genérico quando existe termo de domínio?

### Multi-tenancy
- [ ] Toda query escopa a `current_account`?
- [ ] Foreign key `account_id` em todas as tabelas principais?
- [ ] Index em `account_id` para performance?

### Models
- [ ] Código do model segue a ordem de organização?
- [ ] Estados implementados como enums (não gems de state machine)?
- [ ] Normalizations para limpeza de dados?
- [ ] Lógica complexa extraída para classes com namespace?

### Controllers
- [ ] Actions com menos de 10 linhas?
- [ ] Sem lógica de negócio nos controllers?
- [ ] Usando guard clauses para retornos antecipados?
- [ ] Controllers do Dashboard usando autenticação Devise?

### Banco de Dados
- [ ] Constraints de foreign key em todas as referências?
- [ ] NOT NULL com defaults (não nullable)?
- [ ] Indexes em foreign keys e colunas de query?
- [ ] Check constraints para integridade de dados?

### Jobs
- [ ] Jobs orquestram, não executam?
- [ ] Lógica complexa em namespaced model classes?
- [ ] Idempotentes (seguros para executar múltiplas vezes)?
- [ ] Usando SolidQueue (não Sidekiq)?

### Frontend
- [ ] Usando Hotwire (Turbo + Stimulus)?
- [ ] Stimulus controllers em `app/javascript/controllers/`?
- [ ] Sem JavaScript inline?
- [ ] Eager loading adequado (sem N+1)?

## Cartão de Referência Rápida

```
SEMPRE                              NUNCA
────────────────────────────────────────────────────────────
Constraints de foreign key          Diretório app/services/
Enums para estado                   Result/Context objects
Namespaced model classes            Sidekiq/Redis (use SolidQueue)
Guard clauses                       Fat controllers
Escopar ao current_account          Queries sem filtro de Account
RSpec + FactoryBot                  Testar comportamento do framework
Hotwire + Stimulus                  JavaScript inline
Funcionalidades do PostgreSQL       Dados desnormalizados
```
