require "rails_helper"

RSpec.describe "Connector Actions", type: :request do
  let(:account)   { create(:account) }
  let(:user)      { create(:user) }
  let(:connector) { create(:connector, account: account) }

  before do
    create(:account_user, account: account, user: user)
    create(:subscription, :active, account: account, plan: create(:plan, :starter))
    sign_in user
  end

  describe "GET /connectors/:connector_id/actions" do
    it "lists actions for the connector" do
      action = create(:connector_action, connector: connector)

      get connector_actions_path(connector)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(action.name)
    end
  end

  describe "POST /connectors/:connector_id/actions" do
    it "creates an action, parsing the JSON definition and input schema" do
      expect {
        post connector_actions_path(connector), params: {
          connector_action: {
            name: "ping",
            kind: "http_call",
            definition: { method: "get", path: "/ping" }.to_json,
            input_schema: { type: "object", properties: {} }.to_json
          }
        }
      }.to change(Connector::Action, :count).by(1)

      expect(Connector::Action.last.definition).to eq("method" => "get", "path" => "/ping")
      expect(response).to redirect_to(connector_actions_path(connector))
    end
  end

  describe "POST /connectors/:connector_id/actions/import" do
    it "enqueues the OpenAPI import job" do
      allow(Connector::ImportOpenApiJob).to receive(:perform_later)

      post import_connector_actions_path(connector)

      expect(Connector::ImportOpenApiJob).to have_received(:perform_later).with(connector.id)
      expect(response).to redirect_to(connector_actions_path(connector))
    end
  end

  describe "POST /connectors/:connector_id/actions/:id/test" do
    let(:connector) { create(:connector, account: account, config: { "base_url" => "https://api.example.com" }) }
    let(:action) do
      create(:connector_action, connector: connector, definition: { "method" => "get", "path" => "/ping" })
    end

    it "executes the action and redirects back with the raw result" do
      stub_request(:get, "https://api.example.com/ping").to_return(
        status: 200, body: { "ok" => true }.to_json, headers: { "Content-Type" => "application/json" }
      )

      post test_connector_action_path(connector, action), params: { params: "{}" }

      expect(response).to redirect_to(connector_actions_path(connector))
      expect(flash[:notice]).to include("ok")
    end

    it "redirects back with the error message when execution fails" do
      stub_request(:get, "https://api.example.com/ping").to_return(status: 500)

      post test_connector_action_path(connector, action), params: { params: "{}" }

      expect(response).to redirect_to(connector_actions_path(connector))
      expect(flash[:alert]).to eq("HTTP 500")
    end
  end

  describe "DELETE /connectors/:connector_id/actions/:id" do
    it "destroys the action" do
      action = create(:connector_action, connector: connector)

      expect { delete connector_action_path(connector, action) }.to change(Connector::Action, :count).by(-1)
    end
  end

  describe "tenant isolation" do
    it "returns not found for a connector belonging to another account" do
      other_connector = create(:connector)

      get connector_actions_path(other_connector)

      expect(response).to have_http_status(:not_found)
    end
  end
end
