FactoryBot.define do
  factory :message do
    chat { nil }
    role { "MyString" }
    content { "MyText" }
    model_id { "MyString" }
    input_tokens { 1 }
    output_tokens { 1 }
    tool_call { nil }
  end
end
