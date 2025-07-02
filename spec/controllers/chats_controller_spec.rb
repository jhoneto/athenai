require 'rails_helper'

RSpec.describe ChatsController, type: :controller do
  let(:user) { create(:user) }
  let(:workspace) { create(:workspace, user: user) }
  let(:llm) { create(:llm, workspace: workspace) }
  let(:agent) { create(:agent, workspace: workspace, llm: llm) }
  let(:chat) { create(:chat, agent: agent) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: { workspace_id: workspace.id, agent_id: agent.id }
      expect(response).to be_successful
    end

    it 'assigns @chats' do
      chat
      get :index, params: { workspace_id: workspace.id, agent_id: agent.id }
      expect(assigns(:chats)).to include(chat)
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { workspace_id: workspace.id, agent_id: agent.id, id: chat.id }
      expect(response).to be_successful
    end

    it 'assigns @current_chat' do
      get :show, params: { workspace_id: workspace.id, agent_id: agent.id, id: chat.id }
      expect(assigns(:current_chat)).to eq(chat)
    end
  end

  describe 'POST #create' do
    it 'creates a new chat' do
      expect {
        post :create, params: { workspace_id: workspace.id, agent_id: agent.id }
      }.to change(Chat, :count).by(1)
    end

    it 'redirects to the new chat' do
      post :create, params: { workspace_id: workspace.id, agent_id: agent.id }
      expect(response).to redirect_to(workspace_agent_chat_path(workspace, agent, Chat.last))
    end
  end

  describe 'POST #create_message' do
    before do
      chat_service_instance = instance_double(ChatService)
      service_result = instance_double(ServiceResult, success?: true, error: nil)
      allow(ChatService).to receive(:new).and_return(chat_service_instance)
      allow(chat_service_instance).to receive(:call).and_return(service_result)
    end

    it 'calls ChatService with correct parameters' do
      message_params = { content: 'Test message' }

      post :create_message, params: {
        workspace_id: workspace.id,
        agent_id: agent.id,
        id: chat.id,
        message: message_params
      }, xhr: true

      expect(ChatService).to have_received(:new).with(
        agent: agent,
        payload: {
          chat_id: chat.id,
          message: {
            type: "text",
            text: {
              body: 'Test message'
            }
          }
        }
      )
    end
  end
end
