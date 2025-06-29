FactoryBot.define do
  factory :tool_call do
    message { nil }
    tool_call_id { "MyString" }
    name { "MyString" }
    arguments { "" }
  end
end
