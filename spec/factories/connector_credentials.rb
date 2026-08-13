FactoryBot.define do
  factory :connector_credential, class: "Connector::Credential" do
    connector
    encrypted_secrets { { "api_key" => "secret-token" } }
  end
end
