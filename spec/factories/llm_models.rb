FactoryBot.define do
  factory :llm_model, class: "Llm::Model" do
    sequence(:model_id) { |n| "test-model-#{n}" }
    name { "Test Model" }
    provider { "openai" }
  end
end
