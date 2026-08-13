require "swagger_helper"

RSpec.describe "api/v1/messages", type: :request do
  let(:account) { create(:account) }
  let(:user)    { create(:user) }
  let(:session) { create(:session, account: account, user: user) }
  let(:token)   { ApiKey.create_with_token!(account: account, name: "CI").last }
  let(:Authorization) { "Bearer #{token}" }

  path "/api/v1/sessions/{session_id}/messages" do
    get "Lists messages in a session" do
      tags "Messages"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :session_id, in: :path, type: :integer, required: true

      response "200", "messages found" do
        let(:session_id) { session.id }
        before { create(:message, session: session) }
        run_test!
      end

      response "404", "session belongs to another account" do
        let(:session_id) { create(:session).id }
        run_test!
      end
    end

    post "Sends a message and queues an agent response" do
      tags "Messages"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :session_id, in: :path, type: :integer, required: true
      parameter name: :message, in: :body, schema: {
        type: :object,
        properties: {
          message: {
            type: :object,
            properties: { content: { type: :string } },
            required: [ "content" ]
          }
        }
      }

      response "202", "message queued for the agent to respond" do
        let(:session_id) { session.id }
        let(:message) { { message: { content: "Hello" } } }

        before { allow(AgentResponseJob).to receive(:perform_later) }

        run_test! do
          expect(AgentResponseJob).to have_received(:perform_later).with(session.id)
        end
      end
    end
  end
end
