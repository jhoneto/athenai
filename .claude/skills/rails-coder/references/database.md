# Padrões de Banco de Dados

## Princípios de Design de Schema

### Normalize os Dados

Uma responsabilidade por tabela. Evite colunas desnormalizadas.

```ruby
# Ruim — desnormalizado
create_table :resources do |t|
  t.string :title
  t.string :account_name      # Duplicado de accounts
  t.string :account_email     # Duplicado de accounts
end

# Bom — normalizado
create_table :resources do |t|
  t.string :title
  t.references :account, foreign_key: true, null: false
  t.integer :items_count, default: 0, null: false  # Counter cache
end
```

### Constraints de Foreign Key

Sempre adicione constraints de foreign key:

```ruby
class CreateAccountUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :account_users do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user,    null: false, foreign_key: true
      t.integer :role, null: false, default: 2
      t.timestamps
    end

    add_index :account_users, [:account_id, :user_id], unique: true
  end
end
```

### Check Constraints

Use constraints a nível de banco de dados para integridade de dados:

```ruby
class AddConstraintsToAccountUsers < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :account_users, "role >= 0 AND role <= 2", name: "account_users_valid_role"
  end
end
```

### Defaults NOT NULL

Prefira NOT NULL com defaults em vez de colunas nullable:

```ruby
# Bom
add_column :accounts, :active, :boolean, default: true, null: false
add_column :users, :metadata, :jsonb, default: {}, null: false

# Evitar quando possível
add_column :accounts, :active, :boolean  # Nullable, lógica de três estados
```

## Funcionalidades do PostgreSQL

### Tipos Enum

Use enums do PostgreSQL para conjuntos fixos de valores:

```ruby
class AddRoleEnumToAccountUsers < ActiveRecord::Migration[8.1]
  def up
    create_enum :account_role, %w[owner admin member]
    add_column :account_users, :role_enum, :enum, enum_type: :account_role, default: "member", null: false
  end

  def down
    remove_column :account_users, :role_enum
    drop_enum :account_role
  end
end
```

### Colunas JSONB

Para metadados flexíveis:

```ruby
class AddMetadataToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :metadata, :jsonb, default: {}, null: false
    add_index :accounts, :metadata, using: :gin
  end
end
```

## Estratégia de Indexação

### Indexar Foreign Keys

Sempre indexe colunas de foreign key:

```ruby
# Automático com references
t.references :account, foreign_key: true  # Adiciona index

# Manual
add_index :account_users, :account_id
add_index :account_users, :user_id
```

### Indexar Padrões de Query

```ruby
# Queries de coluna única
add_index :users, :email, unique: true
add_index :users, :reset_password_token, unique: true

# Constraints únicas
add_index :account_users, [:account_id, :user_id], unique: true
```

## Boas Práticas em Migrations

### Migrations Reversíveis

```ruby
class AddActiveToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :active, :boolean, default: true, null: false
  end
end
```

### Operações Seguras para Produção

```ruby
# Adicionar index concurrently (não trava a tabela)
add_index :users, :email, algorithm: :concurrently

# Backfill em lotes
User.in_batches.update_all(active: true)
```

## Otimização de Queries

### Eager Loading

```ruby
# Problema N+1
AccountUser.all.each { |au| puts au.user.name }  # Ruim

# Eager load
AccountUser.includes(:user).each { |au| puts au.user.name }  # Bom
```

### Selecionar Apenas as Colunas Necessárias

```ruby
# Pluck para arrays
User.pluck(:id, :email)  # Retorna array de pares

# Select específico
User.select(:id, :name, :email)
```

### Processamento em Lotes

```ruby
User.find_each(batch_size: 1000) do |user|
  user.process_something
end
```

## Higiene do Schema.rb

Mantenha o schema.rb limpo:
- Remova código comentado
- Garanta formatação consistente
- Verifique se todos os indexes são intencionais
- Confira foreign keys órfãs
