require "swagger_helper"

RSpec.describe "api/v1/connectors", type: :request do
  let(:account) { create(:account) }
  let(:token) { ApiKey.create_with_token!(account: account, name: "CI").last }
  let(:Authorization) { "Bearer #{token}" }

  path "/api/v1/connectors" do
    get "Lists connectors" do
      tags "Connectors"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "returns only connectors for the current account" do
        before do
          create(:connector, account: account)
          create(:connector)
        end

        run_test! do |response|
          expect(JSON.parse(response.body).size).to eq(1)
        end
      end
    end

    post "Creates a connector and enqueues a connection test" do
      tags "Connectors"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :connector, in: :body, schema: {
        type: :object,
        properties: {
          connector: {
            type: :object,
            properties: {
              name: { type: :string },
              kind: { type: :string },
              config: { type: :object }
            }
          }
        }
      }

      response "201", "connector created" do
        let(:connector) do
          { connector: { name: "My API", kind: "rest", config: { base_url: "https://api.example.com" } } }
        end

        before { allow(Connector::TestConnectionJob).to receive(:perform_later) }

        run_test! do
          expect(Connector::TestConnectionJob).to have_received(:perform_later)
        end
      end
    end
  end

  path "/api/v1/connectors/{id}" do
    get "Retrieves a connector" do
      tags "Connectors"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true

      response "200", "connector found" do
        let(:id) { create(:connector, account: account).id }
        run_test!
      end

      response "404", "connector belongs to another account" do
        let(:id) { create(:connector).id }
        run_test!
      end
    end
  end

  path "/api/v1/connectors/{connector_id}/actions" do
    get "Lists connector actions" do
      tags "Connector Actions"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :connector_id, in: :path, type: :integer, required: true

      response "200", "actions found" do
        let(:connector) { create(:connector, account: account) }
        let(:connector_id) { connector.id }

        before { create(:connector_action, connector: connector) }

        run_test!
      end
    end

    post "Creates a connector action" do
      tags "Connector Actions"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :connector_id, in: :path, type: :integer, required: true
      parameter name: :connector_action, in: :body, schema: { type: :object }

      response "201", "action created" do
        let(:connector_id) { create(:connector, account: account).id }
        let(:connector_action) do
          {
            connector_action: {
              name: "ping",
              kind: "http_call",
              definition: { method: "get", path: "/ping" },
              input_schema: { type: "object", properties: {} }
            }
          }
        end

        run_test!
      end
    end
  end
end
