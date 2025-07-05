FactoryBot.define do
  factory :mcp_server do
    name { "MyString" }
    description { "MyText" }
    url { "MyString" }
    headers { "" }
    enabled { false }
    workspace { nil }
  end
end
