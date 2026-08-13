require "swagger_helper"

RSpec.describe "api/v1/sessions", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:agent) { create(:agent, :published, account: account) }
  let(:token) { ApiKey.create_with_token!(account: account, name: "CI").last }
  let(:Authorization) { "Bearer #{token}" }

  before { create(:account_user, account: account, user: user) }

  path "/api/v1/sessions" do
    post "Creates a session for an available agent" do
      tags "Sessions"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :agent_id, in: :query, type: :integer, required: true

      response "201", "session created" do
        let(:agent_id) { agent.id }
        run_test!
      end

      response "404", "agent not found or not published" do
        let(:agent_id) { create(:agent, account: account).id }
        run_test!
      end

      response "401", "unauthorized without a valid api key" do
        let(:Authorization) { "Bearer invalid" }
        let(:agent_id) { agent.id }
        run_test!
      end
    end
  end
end
