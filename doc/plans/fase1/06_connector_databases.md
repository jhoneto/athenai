# Plano 6 — Connector Layer: PostgreSQL

> Reaproveita o contrato criado no Plano 5 (`Connector`, `Connector::Credential`, `Connector::Action`, `Connector::Adapters::Base`). Nenhuma migration nova é necessária — apenas novos adapters e regras de segurança específicas de banco de dados.
>
> MySQL, SQL Server e Oracle ficam fora da Fase 1 — mesmo tratamento dado a Gmail/Microsoft365/S3 em `doc/architecture.md` §4.2: adapters futuros que seguem o mesmo contrato quando forem priorizados.

## Objetivo

- Adapter `Connector::Adapters::Postgres`
- Execução **exclusiva** de `Connector::Action` pré-cadastradas (queries nomeadas e parametrizadas) — nunca SQL livre vindo do LLM ou do usuário final
- Conexão isolada por connector, nunca reaproveitando a conexão principal da aplicação
- Lógica de enforcement (`LIMIT`, timeout) isolada em uma classe intermediária (`RelationalBase`) para que futuros adapters relacionais (MySQL, SQL Server, Oracle) a reaproveitem sem duplicação

## Regras de segurança (não negociáveis)

1. Toda `Connector::Action` do tipo `query` armazena em `definition["sql"]` uma query com placeholders nomeados (`:cliente_id`, nunca interpolação de string)
2. Apenas `SELECT` é permitido — validado tanto na criação da `Connector::Action` (validação de model) quanto em runtime pelo adapter (defesa em profundidade)
3. `LIMIT` é injetado automaticamente pelo adapter se a query não tiver um (`config["max_rows"]`, default 100)
4. Timeout de statement obrigatório (`statement_timeout` no Postgres, `max_execution_time` no MySQL)
5. Credenciais devem apontar, sempre que possível, para um usuário de banco somente leitura — documentar isso na tela de cadastro do conector, não é validável programaticamente

## Model — validação adicional em `Connector::Action`

```ruby
# app/models/connector/action.rb
validate :sql_is_read_only, if: -> { query? }

private

def sql_is_read_only
  sql = definition["sql"].to_s.strip
  return errors.add(:definition, "deve começar com SELECT") unless sql.match?(/\A\s*select/i)
  errors.add(:definition, "não pode conter múltiplos statements") if sql.include?(";")
end
```

## Adapter base para bancos relacionais

`app/models/connector/adapters/relational_base.rb` (classe intermediária pensada para ser compartilhada por todo adapter relacional — hoje só `Postgres` a usa, mas evita duplicar a lógica de `LIMIT`/timeout quando MySQL/SQL Server/Oracle forem adicionados em fase futura)

```ruby
class Connector::Adapters::RelationalBase < Connector::Adapters::Base
  DEFAULT_MAX_ROWS = 100
  STATEMENT_TIMEOUT_MS = 5_000

  def call(action, params)
    raise ExecutionError, "ação não é uma query" unless action.query?

    with_connection do |conn|
      sql = enforce_limit(action.definition["sql"])
      conn.exec_query(sql, "Connector::Action", bind_params(sql, params)).to_a
    end
  end

  def test_connection!
    with_connection { |conn| conn.execute("SELECT 1") }
    @connector.update!(status: :connected)
  rescue => e
    @connector.update!(status: :error)
    raise ExecutionError, e.message
  end

  private

  def enforce_limit(sql)
    return sql if sql =~ /limit\s+\d+/i
    "#{sql.chomp(";")} LIMIT #{@connector.config["max_rows"] || DEFAULT_MAX_ROWS}"
  end

  def bind_params(sql, params)
    params.map { |key, value| ActiveRecord::Relation::QueryAttribute.new(key.to_s, value, ActiveRecord::Type::Value.new) }
  end

  def with_connection
    raise NotImplementedError
  end
end
```

## Adapters concretos

`app/models/connector/adapters/postgres.rb`

```ruby
class Connector::Adapters::Postgres < Connector::Adapters::RelationalBase
  private

  def with_connection
    handler = ActiveRecord::Base.establish_connection(connection_config)
    conn = handler.retrieve_connection
    conn.execute("SET statement_timeout = #{STATEMENT_TIMEOUT_MS}")
    yield conn
  ensure
    handler&.remove_connection
  end

  def connection_config
    secrets = @credential.encrypted_secrets
    {
      adapter: "postgresql",
      host: @connector.config["host"],
      port: @connector.config["port"] || 5432,
      database: @connector.config["database"],
      username: secrets["username"],
      password: secrets["password"]
    }
  end
end
```

Fase futura: `app/models/connector/adapters/mysql.rb` seguiria a mesma estrutura (`adapter: "mysql2"`, timeout via `SET SESSION max_execution_time = ...` ao invés de `statement_timeout`) — fora do escopo da Fase 1.

**Importante**: `establish_connection` cria um *connection handler* isolado por chamada — nunca reutiliza `ActiveRecord::Base.connection` da aplicação, evitando que uma query de conector vaze para o banco principal do Athenai ou vice-versa. A conexão é sempre removida no `ensure`.

## Cadastro de `Connector::Action` para banco (Dashboard)

Reaproveita `ConnectorActionsController` do Plano 5 — a única diferença é o formulário: quando `connector.kind` é `postgres`, o campo `definition` vira um textarea de SQL (com highlight via Stimulus, opcional) e `input_schema` continua sendo o JSON Schema dos parâmetros nomeados usados na query (`:cliente_id` no SQL ⇄ `properties.cliente_id` no schema).

## Botão "Testar ação" (Dashboard)

Já existe desde o Plano 5 (`connector_actions#show` ou ação dedicada `test`) — para bancos de dados, esse botão é a validação manual mais importante antes de a ação virar `Tool`: o desenvolvedor vê o resultado real da query com `LIMIT` aplicado.

## Testes

- `spec/models/connector/action_spec.rb` — validação `sql_is_read_only` (rejeita `INSERT`, `UPDATE`, `DELETE`, múltiplos statements)
- `spec/models/connector/adapters/postgres_spec.rb` — usa um banco de teste real (schema mínimo criado no `before(:all)`) para validar que `LIMIT` é aplicado, timeout é setado, e a conexão é sempre removida (`ensure`) mesmo em caso de erro
- Testes de segurança explícitos: query com `;` é rejeitada antes mesmo de chegar ao adapter

## Critérios de aceite

- [ ] Nenhuma query com `INSERT`/`UPDATE`/`DELETE`/`DROP` é aceita na criação da `Connector::Action`
- [ ] Toda execução aplica `LIMIT` e timeout de statement
- [ ] Conexão de conector nunca vaza para o pool de conexão principal da aplicação
- [ ] Lógica de enforcement (`LIMIT`/timeout) fica isolada em `RelationalBase`, pronta para ser reaproveitada por futuros adapters relacionais (MySQL, SQL Server, Oracle) sem duplicação
