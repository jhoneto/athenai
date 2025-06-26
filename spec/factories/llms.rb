FactoryBot.define do
  factory :llm do
    name { Faker::App.name }
    provider { Llm::PROVIDERS.sample }
    model { "#{provider.downcase}-#{Faker::Number.between(from: 1, to: 4)}" }
    api_key { "sk-#{Faker::Alphanumeric.alphanumeric(number: 48)}" }
    temperature { 0.7 }
    max_tokens { 2000 }
    top_p { 0.9 }
    timeout { 30 }
    association :workspace

    trait :openai do
      name { "GPT-4 Turbo" }
      provider { "OpenAI" }
      model { "gpt-4-turbo-preview" }
      api_key { "sk-#{Faker::Alphanumeric.alphanumeric(number: 48)}" }
      api_url { "https://api.openai.com/v1" }
    end
  end
end
