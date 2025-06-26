FactoryBot.define do
  factory :llm do
    name { Faker::App.name }
    provider { [ 'gpt', 'claude', 'gemini' ].sample }
    model { "#{provider}-#{Faker::Number.between(from: 1, to: 4)}" }
    configs { { temperature: 0.7, max_tokens: 2000 } }
    association :workspace
  end
end
