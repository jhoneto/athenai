# Padrões de Testes (RSpec)

## Regra Principal

**Todo código de teste deve ser escrito em inglês:** `describe`, `context`, `it`, nomes de variáveis, mensagens de expectativa e comentários. O português é reservado para documentação e comunicação com o usuário.

## Organização dos Testes

```
spec/
├── models/              # Testes unitários dos models
├── requests/            # Testes de integração dos controllers
├── system/              # Testes end-to-end no browser
├── forms/               # Testes de form objects
├── queries/             # Testes de query objects
├── jobs/                # Testes de background jobs
├── mailers/             # Testes de mailers
├── factories/           # Definições do FactoryBot
└── support/             # Helpers e configuração
```

## O Que Testar

### Models

Teste lógica de negócio, validações e associations:

```ruby
# spec/models/account_spec.rb
RSpec.describe Account do
  describe "associations" do
    it { is_expected.to have_many(:account_users).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:account_users) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "#owner" do
    it "returns the user with owner role" do
      account = create(:account)
      owner   = create(:user)
      create(:account_user, account: account, user: owner, role: :owner)
      member  = create(:user)
      create(:account_user, account: account, user: member, role: :member)

      expect(account.users.joins(:account_users).where(account_users: { role: :owner }).first).to eq(owner)
    end
  end
end
```

### Request Specs

Teste endpoints HTTP, não internals do controller:

```ruby
# spec/requests/users/registrations_spec.rb
RSpec.describe "Users::Registrations" do
  describe "POST /users" do
    let(:valid_params) do
      {
        user: {
          name: "John Doe",
          email: "john@example.com",
          password: "password123",
          password_confirmation: "password123",
          account_name: "My Clinic"
        }
      }
    end

    it "creates user, account and account_user" do
      expect {
        post user_registration_path, params: valid_params
      }.to change(User, :count).by(1)
        .and change(Account, :count).by(1)
        .and change(AccountUser, :count).by(1)
    end

    it "sets account_user role to owner" do
      post user_registration_path, params: valid_params
      expect(AccountUser.last.role).to eq("owner")
    end

    it "rejects duplicate email" do
      create(:user, email: "john@example.com")
      post user_registration_path, params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

### Job Specs

```ruby
# spec/jobs/welcome_email_job_spec.rb
RSpec.describe WelcomeEmailJob do
  let(:user) { create(:user) }

  describe "#perform" do
    it "enqueues the welcome email" do
      expect { described_class.perform_now(user) }
        .to have_enqueued_mail(UserMailer, :welcome)
    end
  end
end
```

## Padrões do FactoryBot

### Factory Básica

```ruby
# spec/factories/accounts.rb
FactoryBot.define do
  factory :account do
    name { Faker::Company.name }

    trait :with_owner do
      transient do
        owner { create(:user) }
      end

      after(:create) do |account, evaluator|
        create(:account_user, account: account, user: evaluator.owner, role: :owner)
      end
    end
  end
end

# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { "password123" }
    password_confirmation { "password123" }
  end
end

# spec/factories/account_users.rb
FactoryBot.define do
  factory :account_user do
    account
    user
    role { :member }

    trait :owner do
      role { :owner }
    end

    trait :admin do
      role { :admin }
    end
  end
end
```

### Uso

```ruby
# Basic
account = create(:account)
user    = build(:user)  # not persisted

# With traits
account_user = create(:account_user, :owner)

# With overrides
user = create(:user, email: "custom@example.com")

# Lists
users = create_list(:user, 3)
```

## Test Helpers

```ruby
# spec/support/authentication_helper.rb — (included via Devise::Test::IntegrationHelpers)
# Already configured in rails_helper.rb
# Usage in specs:
sign_in create(:user)
```

## O Que NÃO Testar

### Framework Behavior

```ruby
# Do not test Rails/Devise internals
it "has an email attribute" do  # unnecessary
  user = User.new(email: "test@example.com")
  expect(user.email).to eq("test@example.com")
end
```

### Obvious Code

```ruby
# Do not test simple delegations
it "delegates email to user" do  # if using delegate
  expect(account_user.user_email).to eq(account_user.user.email)
end
```

### Generated Code

Do not test:
- Default scopes that only wrap `where`
- Simple presence validations (use shoulda-matchers)
- ActiveRecord callbacks that only call methods

## Configuração do RSpec

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request
end

# Run all tests
# bundle exec rspec

# Run only fast tests (exclude system)
# bundle exec rspec --tag ~type:system

# Run system tests
# bundle exec rspec --tag type:system
```

## Dicas de Velocidade nos Testes

1. **Use `build` em vez de `create`** quando persistência não for necessária
2. **Use `let` em vez de `before`** para avaliação lazy
3. **Evite associations desnecessárias** em factories
4. **Use `create_list` com moderação** — geralmente 2-3 registros são suficientes
5. **Mock serviços externos** em testes unitários
6. **Execute system tests separadamente** dos testes unitários
