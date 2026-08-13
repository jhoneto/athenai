require "rails_helper"

RSpec.describe Connector::Adapters::Http, type: :model do
  let(:connector) { create(:connector, config: { "base_url" => "https://api.example.com", "health_path" => "/health" }) }
  let(:adapter) { described_class.new(connector) }

  describe "#test_connection!" do
    it "marks the connector as connected when the health check succeeds" do
      stub_request(:get, "https://api.example.com/health").to_return(status: 200)

      adapter.test_connection!

      expect(connector.reload).to be_connected
    end

    it "marks the connector as error when the health check fails" do
      stub_request(:get, "https://api.example.com/health").to_return(status: 500)

      adapter.test_connection!

      expect(connector.reload).to be_error
    end

    context "when health_path is blank" do
      let(:connector) { create(:connector, config: { "base_url" => "https://api.example.com", "health_path" => "" }) }

      it "falls back to the root path instead of requesting an empty path" do
        stub_request(:get, "https://api.example.com/").to_return(status: 200)

        adapter.test_connection!

        expect(connector.reload).to be_connected
      end
    end
  end

  describe "#call" do
    let(:action) { create(:connector_action, connector: connector, definition: { "method" => "get", "path" => "/ping" }) }

    it "performs the HTTP call described by the action and returns the parsed body" do
      stub_request(:get, "https://api.example.com/ping").to_return(
        status: 200, body: { "ok" => true }.to_json, headers: { "Content-Type" => "application/json" }
      )

      expect(adapter.call(action, {})).to eq("ok" => true)
    end

    it "raises ExecutionError when the response is not successful" do
      stub_request(:get, "https://api.example.com/ping").to_return(status: 503)

      expect { adapter.call(action, {}) }.to raise_error(Connector::Adapters::Base::ExecutionError, "HTTP 503")
    end

    it "authenticates with the connector credential when present" do
      create(:connector_credential, connector: connector, encrypted_secrets: { "api_key" => "token-123" })
      request_stub = stub_request(:get, "https://api.example.com/ping")
        .with(headers: { "Authorization" => "Bearer token-123" })
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      adapter.call(action, {})

      expect(request_stub).to have_been_requested
    end
  end

  describe "#call with a templated path" do
    let(:action) { create(:connector_action, connector: connector, definition: { "method" => "get", "path" => "/pet/{petId}" }) }

    it "interpolates path parameters and sends the rest as query params" do
      stub = stub_request(:get, "https://api.example.com/pet/42")
        .with(query: { "verbose" => "true" })
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      adapter.call(action, { "petId" => 42, "verbose" => "true" })

      expect(stub).to have_been_requested
    end

    it "raises ExecutionError when a path parameter is missing" do
      expect { adapter.call(action, {}) }.to raise_error(Connector::Adapters::Base::ExecutionError, "missing path parameter: petId")
    end
  end
end
