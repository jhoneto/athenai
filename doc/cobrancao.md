# AI Agent Platform
# Estratégia de Cobrança

## Objetivo

O modelo de cobrança deve atender alguns objetivos:

- Simples de entender para o cliente.
- Independente do provedor de IA utilizado.
- Permitir trocar modelos sem alterar preços.
- Manter margem mesmo com mudanças de custo dos LLMs.
- Ser compatível com OpenAI, Anthropic, Gemini, OpenRouter, RunPod, Ollama e futuros provedores.

A principal decisão é:

> **O cliente nunca compra tokens. Ele compra capacidade de execução da plataforma.**

---

# Conceito

Internamente a plataforma possui um **Cost Engine**.

Externamente o cliente vê apenas **AI Credits**.

```
Cliente

↓

Executa uma tarefa

↓

Consome AI Credits
```

Toda a complexidade permanece escondida.

---

# Por que não cobrar por token?

Problemas:

- O cliente não entende tokens.
- Cada modelo possui preços diferentes.
- O custo muda constantemente.
- Trocar de modelo exige mudar preços.
- Gera insegurança sobre o valor da fatura.

O cliente quer previsibilidade.

---

# AI Credits

O cliente compra créditos mensais.

Exemplo:

```
Starter

5.000 AI Credits
```

```
Professional

25.000 AI Credits
```

```
Enterprise

100.000 AI Credits
```

Os créditos representam capacidade computacional da plataforma.

Não representam tokens.

---

# Perfis de IA

O usuário não escolhe diretamente um modelo.

Ele escolhe um perfil.

```
⚡ Fast
```

Respostas rápidas.

Baixo custo.

---

```
🧠 Balanced
```

Melhor equilíbrio entre velocidade e qualidade.

---

```
🎯 Premium
```

Maior qualidade.

Maior contexto.

Maior custo.

---

```
💎 Deep Reasoning
```

Problemas complexos.

Planejamento.

Raciocínio longo.

---

# Multiplicador

Cada perfil possui um multiplicador.

| Perfil | Multiplicador |
|---------|---------------|
| Fast | 1x |
| Balanced | 2x |
| Premium | 5x |
| Deep Reasoning | 10x |

Exemplo.

Uma mesma tarefa.

```
Resumo de contrato
```

Consumirá:

| Perfil | Créditos |
|---------|-----------|
| Fast | 1 |
| Balanced | 2 |
| Premium | 5 |
| Deep Reasoning | 10 |

O cliente entende facilmente que perfis mais sofisticados consomem mais capacidade.

---

# Independência dos modelos

Internamente.

```
Fast
↓

GPT-5.5 Mini
```

Depois de alguns meses.

```
Fast
↓

Gemini Flash
```

Nada muda para o cliente.

O perfil permanece o mesmo.

---

Outro exemplo.

Hoje.

```
Premium

↓

Claude Sonnet
```

Amanhã.

```
Premium

↓

GPT-5.5
```

Nenhuma alteração comercial.

---

# Vantagens

A plataforma pode:

- trocar modelos;
- adicionar novos provedores;
- reduzir custos;
- aumentar margem;

sem alterar contratos.

---

# Cost Engine

Toda execução gera um custo interno.

Exemplo.

```
LLM

1.800 tokens

R$ 0,035
```

```
Embedding

R$ 0,004
```

```
RAG

R$ 0,002
```

```
OCR

R$ 0,003
```

```
Total

R$ 0,044
```

Esse valor nunca aparece para o cliente.

Serve apenas para:

- monitorar margem;
- identificar desperdícios;
- calcular lucratividade.

---

# Conversão para créditos

O Cost Engine calcula o custo.

Depois aplica o multiplicador do perfil.

Exemplo.

```
Consulta simples
```

Fast.

```
1 crédito
```

Balanced.

```
2 créditos
```

Premium.

```
5 créditos
```

Reasoning.

```
10 créditos
```

O cliente sempre enxerga apenas créditos.

---

# Routing Inteligente

A plataforma pode possuir um modo automático.

```
Strategy

Auto
```

A IA escolhe o modelo mais adequado.

Exemplo.

```
Pergunta simples

↓

Fast
```

---

```
Comparar contratos

↓

Premium
```

---

```
Planejamento estratégico

↓

Deep Reasoning
```

O cliente continua sem conhecer o modelo real.

---

# Benefícios do Routing

- reduz custos;
- melhora performance;
- aumenta margem;
- evita desperdício.

---

# AI Profiles

Os perfis deixam de representar um modelo.

Eles representam uma experiência.

```
Fast

↓

Resposta rápida
```

```
Balanced

↓

Uso geral
```

```
Premium

↓

Alta qualidade
```

```
Reasoning

↓

Problemas complexos
```

Isso protege a plataforma das constantes mudanças do mercado de IA.

---

# Planos

## Starter

- 5.000 AI Credits
- Fast
- Até 3 agentes
- Até 3 conectores
- 1 GB de Knowledge Base

---

## Professional

- 25.000 AI Credits
- Fast
- Balanced
- Premium
- Até 20 agentes
- Até 20 conectores
- 20 GB de documentos

---

## Enterprise

- AI Credits personalizados
- Todos os perfis
- Deep Reasoning
- Agentes ilimitados
- Conectores ilimitados
- Multiempresa
- Auditoria
- SSO
- API ilimitada
- BYOK (Bring Your Own Key)

---

# Bring Your Own Key (BYOK)

Clientes Enterprise poderão informar suas próprias credenciais.

Exemplo.

- OpenAI
- Anthropic
- Gemini
- OpenRouter

Nesse cenário.

A plataforma cobra apenas:

- infraestrutura;
- conectores;
- agentes;
- memória;
- auditoria;
- execução.

Os custos dos modelos ficam sob responsabilidade do cliente.

---

# Dashboard Administrativo

O administrador visualizará métricas como.

```
Empresa XPTO

AI Credits

Consumidos

18.450

Restantes

6.550
```

Também poderá visualizar.

- agentes mais utilizados;
- custo médio por execução;
- custo por empresa;
- margem;
- utilização por perfil.

Essas informações ficam disponíveis apenas para administração da plataforma.

---

# Modelo Comercial

O cliente compra:

- Agentes
- Conectores
- AI Credits
- Espaço para Knowledge Base

O cliente NÃO compra:

- Tokens
- GPT
- Claude
- Gemini

A plataforma decide automaticamente qual tecnologia utilizar.

---

# Princípios

A estratégia de cobrança deve seguir alguns princípios fundamentais.

## Simplicidade

O cliente nunca precisa entender tokens.

---

## Previsibilidade

Todo plano possui quantidade conhecida de AI Credits.

---

## Flexibilidade

Os modelos podem ser alterados sem impacto comercial.

---

## Escalabilidade

Novos provedores podem ser adicionados sem alterar contratos.

---

## Independência

A plataforma nunca fica dependente de um fornecedor específico de IA.

---

# Visão de Longo Prazo

A plataforma deixa de vender acesso a modelos de linguagem.

Ela passa a vender **capacidade operacional de agentes inteligentes**.

Os modelos de IA tornam-se um detalhe de implementação.

O verdadeiro valor está na infraestrutura construída ao redor deles:

- Agent Engine
- Connectors
- Knowledge Base
- Security
- Memory
- Observability
- API
- Multiempresa
- Governança

Os AI Credits representam o consumo dessa infraestrutura, tornando a plataforma sustentável, previsível e preparada para evoluir conforme o mercado de IA muda.