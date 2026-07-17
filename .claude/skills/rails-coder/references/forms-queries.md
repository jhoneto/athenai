# Form Objects & Query Objects

## Quando Usar Form Objects

Use form objects quando:
- A operação abrange múltiplos models
- Validações complexas além de um único model
- Necessidade de fronteiras de transação
- Desacoplamento do formulário da estrutura do model

**Não use para:**
- CRUD simples de um único model
- Validações básicas (use as validações do model)

## Padrão de Form Object

### Classe Base

```ruby
# app/forms/application_form.rb
class ApplicationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      submit!
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    errors.merge!(e.record.errors)
    false
  end

  private

  def submit!
    raise NotImplementedError
  end
end
```

### Exemplo: Formulário de Registro

```ruby
# app/forms/registration_form.rb
class RegistrationForm < ApplicationForm
  attribute :user_name, :string
  attribute :account_name, :string
  attribute :email, :string
  attribute :password, :string

  validates :user_name, presence: true
  validates :account_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }

  attr_reader :user, :account

  private

  def submit!
    @user = User.create!(
      name: user_name,
      email: email,
      password: password
    )

    @account = Account.create!(name: account_name)

    @account.account_users.create!(user: @user, role: :owner)
  end
end
```

### Uso no Controller

```ruby
class RegistrationsController < ApplicationController
  def new
    @form = RegistrationForm.new
  end

  def create
    @form = RegistrationForm.new(registration_params)

    if @form.save
      sign_in @form.user
      redirect_to dashboard_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:registration).permit(:user_name, :account_name, :email, :password)
  end
end
```

## Padrão de Query Object

Use query objects para:
- Queries complexas com múltiplas condições
- Lógica de query reutilizável
- Queries que precisam ser testadas isoladamente
- Queries com filtros dinâmicos

### Classe Base

```ruby
# app/queries/application_query.rb
class ApplicationQuery
  def initialize(relation = default_relation)
    @relation = relation
  end

  def call
    raise NotImplementedError
  end

  private

  attr_reader :relation

  def default_relation
    raise NotImplementedError
  end
end
```

### Query Object com Parâmetros

```ruby
# app/queries/user/search_query.rb
class User::SearchQuery < ApplicationQuery
  def initialize(relation = User.all, params = {})
    super(relation)
    @params = params
  end

  def call
    result = relation
    result = filter_by_role(result)
    result = search_by_name(result)
    result = apply_sorting(result)
    result
  end

  private

  attr_reader :params

  def default_relation
    User.all
  end

  def filter_by_role(rel)
    return rel if params[:role].blank?
    rel.joins(:account_users).where(account_users: { role: params[:role] })
  end

  def search_by_name(rel)
    return rel if params[:q].blank?
    rel.where("name ILIKE ?", "%#{params[:q]}%")
  end

  def apply_sorting(rel)
    case params[:sort]
    when "oldest" then rel.order(created_at: :asc)
    when "name"   then rel.order(name: :asc)
    else rel.order(created_at: :desc)
    end
  end
end

# Uso:
User::SearchQuery.new(current_account.users, role: "admin", q: "João").call
```

### Uso no Controller

```ruby
class Dashboard::UsersController < Dashboard::ApplicationController
  def index
    @users = User::SearchQuery.new(
      current_account.users,
      search_params
    ).call.page(params[:page])
  end

  private

  def search_params
    params.permit(:role, :q, :sort)
  end
end
```

## Testes

### Testes de Form Object

```ruby
# spec/forms/registration_form_spec.rb
RSpec.describe RegistrationForm do
  describe "validações" do
    it "exige user_name" do
      form = described_class.new(user_name: "")
      expect(form).not_to be_valid
    end

    it "exige account_name" do
      form = described_class.new(account_name: "")
      expect(form).not_to be_valid
    end
  end

  describe "#save" do
    let(:valid_params) do
      {
        user_name: "João Silva",
        account_name: "Minha Empresa",
        email: "joao@example.com",
        password: "senha12345"
      }
    end

    it "cria user, account e account_user" do
      form = described_class.new(valid_params)

      expect { form.save }
        .to change(User, :count).by(1)
        .and change(Account, :count).by(1)
        .and change(AccountUser, :count).by(1)
    end

    it "define role como owner" do
      form = described_class.new(valid_params)
      form.save
      expect(AccountUser.last.role).to eq("owner")
    end
  end
end
```

### Testes de Query Object

```ruby
# spec/queries/user/search_query_spec.rb
RSpec.describe User::SearchQuery do
  let(:account) { create(:account) }
  let!(:owner) { create(:user, name: "João Silva") }
  let!(:member) { create(:user, name: "Maria Santos") }

  before do
    create(:account_user, account: account, user: owner, role: :owner)
    create(:account_user, account: account, user: member, role: :member)
  end

  describe "#call" do
    it "filtra por role" do
      result = described_class.new(account.users, role: "owner").call
      expect(result).to include(owner)
      expect(result).not_to include(member)
    end

    it "busca por nome" do
      result = described_class.new(account.users, q: "João").call
      expect(result).to include(owner)
      expect(result).not_to include(member)
    end
  end
end
```

## Comparação: Scopes vs Query Objects

### Use Scopes Quando

- Filtros simples de uma única condição
- Frequentemente encadeados com outros scopes
- Fazem parte da identidade central do model

```ruby
class User < ApplicationRecord
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(active: true) }
end
```

### Use Query Objects Quando

- Múltiplas condições interagindo
- Lógica de negócio complexa
- Combinações de filtros dinâmicos
- Necessidade de testes isolados

```ruby
User::SearchQuery.new(relation, params).call
```
