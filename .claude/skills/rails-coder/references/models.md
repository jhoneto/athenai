# Padrões de Model

## Convenções de Nomenclatura

Use a linguagem do domínio para nomear models:

| Genérico | Domínio Athenai |
|----------|-----------------|
| Company / Tenant | `Account` |
| User | `User` (com role por Account) |

Escolha nomes que refletem o que a entidade representa no negócio, não a implementação técnica.

## Ordem de Organização

Organize o código do model nessa ordem exata:

```ruby
class User < ApplicationRecord
  # 1. Gems/extensões DSL
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  # 2. Associations
  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users

  # 3. Enums (para máquinas de estado)
  # enum :status, %w[active inactive].index_by(&:itself)

  # 4. Normalizations (Rails 7.1+)
  normalizes :email, with: ->(e) { e.strip.downcase }

  # 5. Validations
  validates :name, presence: true

  # 6. Scopes
  scope :recent, -> { order(created_at: :desc) }

  # 7. Callbacks
  # after_create_commit :send_welcome_email

  # 8. Delegations
  # delegate :name, to: :account, prefix: true

  # 9. Métodos públicos
  def owner_of?(account)
    account_users.exists?(account: account, role: :owner)
  end

  # 10. Métodos privados
  private
end
```

## Enums para Estado

Sempre use enums para gerenciamento de estado em vez de gems de state machine:

```ruby
# Definir enum com mapeamento explícito
enum :role, { owner: 0, admin: 1, member: 2 }

# Tipo enum do PostgreSQL (recomendado para tabelas grandes)
# Na migration:
create_enum :user_status, %w[active inactive suspended]
add_column :users, :status, :enum, enum_type: :user_status, default: "active", null: false

# Métodos de query são gerados automaticamente:
user.active?       # => true/false
user.inactive!     # transiciona o estado
User.active        # => scope
```

## Associations

### Counter Caches

Toda association `has_many` deve incluir counter cache quando performance for relevante:

```ruby
class Account < ApplicationRecord
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
end

class AccountUser < ApplicationRecord
  belongs_to :account, counter_cache: true
  belongs_to :user
end

# Migration:
add_column :accounts, :account_users_count, :integer, default: 0, null: false
```

### Opções de Dependent

Escolha a opção de dependent adequada:

```ruby
has_many :account_users, dependent: :destroy    # destroi filhos, executa callbacks
has_many :logs, dependent: :delete_all          # delete rápido, ignora callbacks
has_many :comments, dependent: :nullify         # mantém registros, remove FK
```

## Normalizations (Rails 7.1+)

Use `normalizes` para limpeza de dados:

```ruby
class User < ApplicationRecord
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip.squeeze(" ") }
end

# Aplicado automaticamente na atribuição e na query:
user.email = "  JOHN@EXAMPLE.COM  "
user.email  # => "john@example.com"
```

## Scopes

Mantenha scopes simples e combináveis:

```ruby
class AccountUser < ApplicationRecord
  scope :recent, -> { order(created_at: :desc) }
  scope :owners, -> { where(role: :owner) }
  scope :by_account, ->(account) { where(account: account) }
end

# Uso:
AccountUser.owners.by_account(current_account)
```

Para queries complexas, use Query Objects (veja `forms-queries.md`).

## Validations

```ruby
class Account < ApplicationRecord
  validates :name, presence: true
  validates :name, length: { maximum: 100 }
  validates :subdomain, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
end
```

## Extraindo Lógica Complexa

### Quando Extrair

Extraia para classe com namespace quando:
- Método excede 15 linhas
- Lógica chama APIs externas
- Lógica envolve algoritmos complexos
- Lógica é reutilizável em diferentes contextos

### Namespaced Model Classes

```ruby
# app/models/user/importer.rb
class User::Importer
  def initialize(account, rows)
    @account = account
    @rows = rows
  end

  def call
    rows.map { |row| import_row(row) }.compact
  end

  private

  attr_reader :account, :rows

  def import_row(row)
    user = User.find_or_initialize_by(email: row[:email])
    user.assign_attributes(name: row[:name])
    user.save!
    account.account_users.find_or_create_by!(user: user, role: :member)
    user
  rescue ActiveRecord::RecordInvalid
    nil
  end
end

# Uso:
User::Importer.new(account, csv_rows).call
```

## Callbacks

Use callbacks com moderação:

```ruby
class User < ApplicationRecord
  # Bom — agendando trabalho assíncrono
  after_create_commit :send_welcome_email_job

  private

  def send_welcome_email_job
    WelcomeEmailJob.perform_later(self)
  end
end
```

**Evite:**
- Lógica complexa em callbacks
- Callbacks que chamam serviços externos de forma síncrona
- Cadeias de callbacks profundamente aninhadas
- Callbacks que modificam outros registros (use jobs em vez disso)
