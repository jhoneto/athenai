FactoryBot.define do
  factory :function do
    name { Faker::Name.unique.name }
    code { Faker::Lorem.paragraph }
    description { Faker::Lorem.sentence }
    parameters { { "input" => { "type" => "string", "required" => true, "description" => "Input parameter" } } }
    tool_type { "custom" }
    association :workspace
  end
end
