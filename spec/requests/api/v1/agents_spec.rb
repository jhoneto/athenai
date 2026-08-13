require "swagger_helper"

RSpec.describe "api/v1/agents", type: :request do
  let(:account) { create(:account) }
  let(:token) { ApiKey.create_with_token!(account: account, name: "CI").last }
  let(:Authorization) { "Bearer #{token}" }

  path "/api/v1/agents" do
    get "Lists available agents" do
      tags "Agents"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "returns only published agents for the current account" do
        before do
          create(:agent, :published, account: account)
          create(:agent, account: account)
          create(:agent, :published)
        end

        run_test! do |response|
          expect(JSON.parse(response.body).size).to eq(1)
        end
      end

      response "401", "unauthorized without a valid api key" do
        let(:Authorization) { "Bearer invalid" }
        run_test!
      end
    end
  end

  path "/api/v1/agents/{id}" do
    get "Retrieves an agent" do
      tags "Agents"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true

      response "200", "agent found" do
        let(:id) { create(:agent, :published, account: account).id }
        run_test!
      end

      response "404", "agent belongs to another account" do
        let(:id) { create(:agent, :published).id }
        run_test!
      end
    end
  end
end
