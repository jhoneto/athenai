Plan.find_or_create_by!(slug: "starter") do |p|
  p.name               = "Starter"
  p.analyses_per_month = 50
  p.price_cents        = 29_700
  p.active             = true
end

Plan.find_or_create_by!(slug: "growth") do |p|
  p.name               = "Growth"
  p.analyses_per_month = 300
  p.price_cents        = 79_700
  p.active             = true
end

Plan.find_or_create_by!(slug: "enterprise") do |p|
  p.name               = "Enterprise"
  p.analyses_per_month = nil
  p.price_cents        = 0
  p.active             = true
end

account = Account.find_or_create_by!(name: "Athenai Demo")

user = User.find_or_initialize_by(email: "admin@athenai.test")
user.name = "Admin Athenai"
user.password = "password123"
user.password_confirmation = "password123"
user.save!

AccountUser.find_or_create_by!(account: account, user: user) do |account_user|
  account_user.role = :owner
end

Subscription.find_or_create_by!(account: account) do |subscription|
  subscription.status = :active
  subscription.plan   = Plan.find_by!(slug: "growth")
end

Llm::Model.find_or_create_by!(provider: "anthropic", model_id: "claude-sonnet-5") do |model|
  model.name              = "Claude Sonnet 5"
  model.context_window    = 200_000
  model.max_output_tokens = 8_192
  model.pricing           = { input_per_million: 3.0, output_per_million: 15.0 }
end

Llm::Model.find_or_create_by!(provider: "gemini", model_id: "gemini-flash") do |model|
  model.name              = "Gemini Flash"
  model.context_window    = 1_000_000
  model.max_output_tokens = 8_192
  model.pricing           = { input_per_million: 0.35, output_per_million: 1.05 }
end

openai_model = Llm::Model.find_or_create_by!(provider: "openai", model_id: "gpt-5-mini") do |model|
  model.name              = "GPT-5 Mini"
  model.context_window    = 400_000
  model.max_output_tokens = 16_384
  model.pricing           = { input_per_million: 0.25, output_per_million: 2.0 }
end

{
  fast: [ openai_model, 1 ],
  balanced: [ openai_model, 2 ],
  premium: [ openai_model, 5 ],
  deep_reasoning: [ openai_model, 10 ]
}.each do |key, (model, multiplier)|
  profile = Llm::Profile.find_or_initialize_by(key: key)
  profile.name              = key.to_s.titleize
  profile.llm_model         = model
  profile.credit_multiplier = multiplier
  profile.save!
end

Agent.find_or_create_by!(account: account, name: "Assistente de Suporte") do |agent|
  agent.description   = "Responde dúvidas gerais sobre o produto."
  agent.system_prompt = "Você é um assistente de suporte educado e objetivo."
  agent.llm_profile    = Llm::Profile.find_by!(key: :fast)
  agent.status         = :published
end

Agent.find_or_create_by!(account: account, name: "Analista Financeiro") do |agent|
  agent.description   = "Consulta boletos e pagamentos (rascunho, ainda sem publicar)."
  agent.system_prompt = "Você é um analista financeiro que consulta o ERP do cliente."
  agent.llm_profile    = Llm::Profile.find_by!(key: :premium)
end

support_agent = Agent.find_by!(account: account, name: "Assistente de Suporte")

Session.find_or_create_by!(account: account, agent: support_agent, user: user) do |session|
  session.title = "Primeira conversa"
end

puts "Seed concluído: login com admin@athenai.test / password123"
