# Fase 1 (MVP) — Plano geral

> Detalha [`doc/architecture.md`](../../architecture.md) em incrementos menores e sequenciáveis. Cada plano é independente o suficiente para virar um PR (ou uma pequena série de PRs), mas respeita a ordem de dependência abaixo.
>
> **Pré-requisito**: [`Plano 0 — Setup do RubyLLM & Catálogo de Modelos`](../00_ruby_llm_setup.md) deve ser implementado antes do Plano 1. Ele define `Llm::Model`/`Llm::Profile`, referenciados pelo `Agent` (Plano 1) e pelo `Session` (Plano 3), conforme a estratégia de cobrança em [`doc/cobrancao.md`](../../cobrancao.md).

## Planos

| # | Plano | Depende de |
|---|---|---|
| 0 | [Setup do RubyLLM & Catálogo de Modelos](../00_ruby_llm_setup.md) | — |
| 1 | [Agents Core](01_agents_core.md) | Account/User (já existe), Plano 0 |
| 2 | [LLM Credentials & RubyLLM](02_llm_credentials.md) | 1 |
| 3 | [Sessions, Messages & Chat Web](03_sessions_chat.md) | 1, 2 |
| 4 | [Knowledge Base & RAG simples](04_knowledge_base_rag.md) | 1 |
| 5 | [Connector Layer — HTTP/OpenAPI](05_connector_http_openapi.md) | 1 |
| 6 | [Connector Layer — PostgreSQL/MySQL](06_connector_databases.md) | 5 |
| 7 | [API REST v1 + Swagger](07_api_rest_v1.md) | 1, 2, 3, 5, 6 (expõe tudo) |
| 8 | [AI Credits & Cost Engine](08_ai_credits_cost_engine.md) | 0, 1, 3 — tem uma decisão de produto pendente, ver o plano |

## Ordem sugerida de execução

1. **Agents Core** — sem isso nada mais existe (é o tenant-child raiz da plataforma)
2. **LLM Credentials** — necessário antes do chat funcionar de ponta a ponta
3. **Sessions/Chat** — primeira entrega demonstrável (Copilot Web conversando com um Agent)
4. **Knowledge Base/RAG** — pode ser feito em paralelo ao Connector Layer (não depende dele)
5. **Connector HTTP/OpenAPI** — primeiro tipo de conector, mais simples que banco de dados
6. **Connector Postgres/MySQL** — reaproveita o contrato de adapter criado no passo 5
7. **API REST v1 + Swagger** — expõe tudo publicamente para o software cliente consumir; feito por último pois consolida os endpoints de todos os módulos anteriores
8. **AI Credits & Cost Engine** — fecha o ciclo comercial; pode ser feito logo após o Plano 3 (não precisa esperar Connector Layer/API), mas exige antes uma decisão de produto sobre o schema de `Subscription` (ver plano)

## Convenções aplicadas em todos os planos

- Sem `app/services/` — operações multi-model viram classes com namespace no model (`Tool::Executor`, `Connector::OpenApiImporter`)
- Toda tabela nova tem `account_id` (direto ou via associação), FK com `on_delete`, e index apropriado
- Estados via `enum`, nunca `string` solto
- Segredos sempre com `encrypts`, nunca em colunas jsonb abertas
- Controllers com no máximo 10 linhas por action, sem lógica de negócio
- Testes em **inglês** (`describe`, `it`, variáveis) — [[feedback_tests_in_english]]
- RSpec + FactoryBot + Faker, organizados por tipo (`spec/models`, `spec/requests`, `spec/jobs`)
