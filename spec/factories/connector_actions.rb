FactoryBot.define do
  factory :connector_action, class: "Connector::Action" do
    connector
    sequence(:name) { |n| "action_#{n}" }
    kind { :http_call }
    input_schema { { "type" => "object", "properties" => {} } }
    definition { { "method" => "get", "path" => "/ping" } }
  end
end
