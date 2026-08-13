FactoryBot.define do
  factory :connector do
    account
    sequence(:name) { |n| "Connector #{n}" }
    kind { :rest }
    config { { "base_url" => "https://api.example.com" } }
    status { :pending }

    trait :openapi do
      kind { :openapi }
      config { { "base_url" => "https://api.example.com", "spec_url" => "https://api.example.com/openapi.json" } }
    end
  end
end
