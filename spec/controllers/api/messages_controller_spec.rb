require 'rails_helper'

RSpec.describe Api::MessagesController, type: :controller do
  let(:workspace) { create(:workspace) }
  let(:agent) { create(:agent, workspace: workspace, uuid: 'test-agent-uuid') }
  let(:chat_service_response) { { message: 'AI response', status: 'success' } }

  before do
    request.headers['X-API-Secret'] = workspace.api_secret
    allow(ChatService).to receive(:call).and_return(chat_service_response)
  end

  describe "POST #create" do
    let(:valid_params) {
      {
        workspace_api_key: workspace.api_key,
        agent: agent.uuid,
        message: 'Hello AI'
      }
    }

    context "with valid API credentials" do
      it "returns a success response" do
        post :create, params: valid_params
        expect(response).to be_successful
      end

      it "calls ChatService with correct parameters" do
        post :create, params: valid_params
        expect(ChatService).to have_received(:call).with(
          agent: agent,
          payload: have_attributes(class: ActionController::Parameters)
        )
      end

      it "returns ChatService response as JSON" do
        post :create, params: valid_params
        expect(JSON.parse(response.body)).to eq(chat_service_response.stringify_keys)
      end

      it "assigns current_workspace" do
        post :create, params: valid_params
        expect(controller.send(:current_workspace)).to eq(workspace)
      end
    end

    context "when agent is not found" do
      let(:invalid_agent_params) {
        valid_params.merge(agent: 'non-existent-uuid')
      }

      it "calls ChatService with nil agent" do
        post :create, params: invalid_agent_params
        expect(ChatService).to have_received(:call).with(
          agent: nil,
          payload: have_attributes(class: ActionController::Parameters)
        )
      end
    end

    context "with invalid API credentials" do
      context "when API secret is missing" do
        before do
          request.headers['X-API-Secret'] = nil
        end

        it "returns unauthorized status" do
          post :create, params: valid_params
          expect(response).to have_http_status(:unauthorized)
        end

        it "returns error message" do
          post :create, params: valid_params
          expect(JSON.parse(response.body)['error']).to eq('API key and secret are required')
        end
      end

      context "when API credentials are invalid" do
        let(:invalid_params) {
          valid_params.merge(workspace_api_key: 'invalid-key')
        }

        it "returns unauthorized status" do
          post :create, params: invalid_params
          expect(response).to have_http_status(:unauthorized)
        end

        it "returns error message" do
          post :create, params: invalid_params
          expect(JSON.parse(response.body)['error']).to eq('Invalid API credentials')
        end
      end
    end

    context "when ChatService raises an exception" do
      before do
        allow(ChatService).to receive(:call).and_raise(StandardError.new('Service error'))
      end

      it "returns internal server error status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:internal_server_error)
      end

      it "returns error message" do
        post :create, params: valid_params
        expect(JSON.parse(response.body)['error']).to eq('Service error')
      end
    end

    context "when ChatService raises ActiveRecord::RecordNotFound" do
      before do
        allow(ChatService).to receive(:call).and_raise(ActiveRecord::RecordNotFound.new('Record not found'))
      end

      it "returns internal server error status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:internal_server_error)
      end

      it "returns error message" do
        post :create, params: valid_params
        expect(JSON.parse(response.body)['error']).to eq('Record not found')
      end
    end
  end
end
