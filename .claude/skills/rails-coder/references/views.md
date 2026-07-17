# Padrões de Views & Frontend

## Stack Tecnológica

- **Hotwire** — Turbo (atualizações de página) + Stimulus (JavaScript pontual)
- **Importmap** — Módulos ES sem build step Node.js (sem Vite, sem Webpack)
- **Tailwind CSS v4** — Utilitários; tema configurado via `@theme` em CSS
- **ERB** — Template engine (não Haml/Slim)
- **ViewComponent** — Não instalado atualmente; adicionar se necessário para componentes reutilizáveis complexos

## Stimulus Controllers

### Localização

Controllers ficam em `app/javascript/controllers/` e são carregados automaticamente via `eagerLoadControllersFrom`:

```javascript
// app/javascript/controllers/index.js
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
```

Nenhum registro manual necessário — basta criar o arquivo `*_controller.js`.

### Controller Básico

```javascript
// app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]
  static values = { successMessage: String }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value)
  }
}
```

```erb
<div data-controller="clipboard" data-clipboard-success-message-value="Copiado!">
  <input data-clipboard-target="source" value="<%= @api_key.token %>" readonly>
  <button data-action="clipboard#copy">Copiar</button>
</div>
```

### Padrões Comuns

```javascript
// Alternar visibilidade
export default class extends Controller {
  static targets = ["content"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
  }
}

// Envio de formulário
export default class extends Controller {
  static targets = ["submit"]

  disable() {
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Salvando..."
  }

  enable() {
    this.submitTarget.disabled = false
    this.submitTarget.textContent = "Salvar"
  }
}

// Auto-submit ao alterar
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
```

### Comunicação entre Controllers

```javascript
// Disparar eventos customizados
this.dispatch("selected", { detail: { id: this.idValue } })

// Ouvir em outro controller
handleSelected({ detail: { id } }) {
  this.outputTarget.textContent = id
}
```

## Padrões Hotwire

### Turbo Drive

Navegação automática sem recarregamento completo:

```erb
<%= link_to "Ver Usuário", dashboard_user_path(@user) %>
<%# Desativar para links específicos %>
<%= link_to "Externo", "https://example.com", data: { turbo: false } %>
```

### Turbo Frames

Atualizações parciais de página:

```erb
<%= turbo_frame_tag @user do %>
  <h1><%= @user.name %></h1>
  <%= link_to "Editar", edit_dashboard_user_path(@user) %>
<% end %>
```

### Turbo Streams

Atualizações em tempo real:

```erb
<%# app/views/dashboard/users/create.turbo_stream.erb %>
<%= turbo_stream.prepend "users", @user %>
<%= turbo_stream.update "users_count", User.count %>
```

## Tailwind CSS v4

Tokens de tema são definidos em `app/assets/tailwind/application.css` via `@theme`:

```css
@import "tailwindcss";

@variant dark (&:where(.dark, .dark *));

@theme {
  --color-brand-primary: #0D1F5C;
  --color-brand-accent: #F5A820;
  --color-canvas: #F4F7FC;
  --color-panel: #FFFFFF;
  --color-ink: #1A1A2E;
  --color-edge: #E2E8F0;

  /* Dark mode */
  --color-canvas-dark: #0F172A;
  --color-panel-dark: #1E293B;
  --color-ink-dark: #E2E8F0;
  --color-edge-dark: #334155;
}
```

Uso nas views:

```erb
<%# Classes geradas automaticamente dos tokens %>
<div class="bg-canvas dark:bg-canvas-dark">
  <div class="rounded-xl border border-edge bg-panel p-5 dark:border-edge-dark dark:bg-panel-dark">
    ...
  </div>
</div>
```

## Boas Práticas em Views

### Mantenha Views Simples

```erb
<%# Bom — lógica simples %>
<% @users.each do |user| %>
  <div class="..."><%= user.name %></div>
<% end %>

<%# Ruim — lógica complexa na view %>
<% @users.select { |u| u.active? && u.account.active? }.each do |user| %>
  <% if user.profile.present? && user.profile["bio"] %>
    ...
  <% end %>
<% end %>
```

### Evite Queries N+1

```ruby
# Controller
@users = current_account.users.includes(:account_users).order(:name)

# View — sem queries adicionais
<% @users.each do |user| %>
  <p><%= user.name %></p>
<% end %>
```

### Partials para Estrutura

Use partials para:
- Templates simples e pontuais
- Layouts e estrutura compartilhada
- Respostas Turbo Stream

```erb
<%# Sidebar como partial do layout %>
<%= render "layouts/sidebar" %>
<%= render "layouts/topbar" %>
```

## Layout Auth

O layout de autenticação usa uma estrutura de card centralizado:

```
<body>
  <div class="flex min-h-full items-center justify-center">
    <div class="w-full max-w-sm">
      Logo
      Flash messages
      <div class="card"> ← formulário aqui </div>
    </div>
  </div>
</body>
```

## Padrões de Formulário

### Formulário Básico

```erb
<%= form_with model: @user, url: user_registration_path do |f| %>
  <div>
    <%= f.label :name, "Nome" %>
    <%= f.text_field :name, class: "..." %>
  </div>
  <%= f.submit "Criar conta" %>
<% end %>
```

### Formulário com Turbo

```erb
<%# Atualizações inline no formulário %>
<%= form_with model: @resource, data: { turbo_frame: "_top" } do |f| %>
  ...
<% end %>
```
