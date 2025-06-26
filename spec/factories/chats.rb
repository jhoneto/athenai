FactoryBot.define do
  factory :chat do
    model_id { "gpt-4-turbo-preview" }
    association :agent
  end
end
