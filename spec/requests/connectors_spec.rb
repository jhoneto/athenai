require "rails_helper"

RSpec.describe "Connectors", type: :request do
  let(:account) { create(:account) }
  let(:user)    { create(:user) }

  before do
    create(:account_user, account: account, user: user)
    create(:subscription, :active, account: account, plan: create(:plan, :starter))
    sign_in user
  end

  describe "GET /connectors" do
    it "lists connectors belonging to the current account" do
      connector = create(:connector, account: account)

      get connectors_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(connector.name)
    end
  end

  describe "POST /connectors" do
    it "creates a connector and enqueues a connection test" do
      allow(Connector::TestConnectionJob).to receive(:perform_later)

      expect {
        post connectors_path, params: {
          connector: { name: "My API", kind: "rest", config: { base_url: "https://api.example.com" } }
        }
      }.to change(Connector, :count).by(1)

      expect(Connector::TestConnectionJob).to have_received(:perform_later).with(Connector.last.id)
      expect(response).to redirect_to(connector_path(Connector.last))
    end
  end

  describe "POST /connectors/:id/test" do
    it "enqueues a new connection test" do
      connector = create(:connector, account: account)
      allow(Connector::TestConnectionJob).to receive(:perform_later)

      post test_connector_path(connector)

      expect(Connector::TestConnectionJob).to have_received(:perform_later).with(connector.id)
      expect(response).to redirect_to(connector_path(connector))
    end
  end

  describe "DELETE /connectors/:id" do
    it "destroys the connector" do
      connector = create(:connector, account: account)

      expect { delete connector_path(connector) }.to change(Connector, :count).by(-1)
      expect(response).to redirect_to(connectors_path)
    end
  end

  describe "tenant isolation" do
    it "returns not found for a connector belonging to another account" do
      other_connector = create(:connector)

      get connector_path(other_connector)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the account plan does not include the http_connector feature" do
    before { account.subscription.update!(plan: create(:plan)) }

    it "redirects to billing" do
      get connectors_path

      expect(response).to redirect_to(billing_path)
    end
  end
end
