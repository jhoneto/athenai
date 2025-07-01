require 'rails_helper'

RSpec.describe AgentFunctionsController, type: :controller do
  let(:user) { create(:user) }
  let(:workspace) { create(:workspace, user: user) }
  let(:agent) { create(:agent, workspace: workspace) }

  before do
    sign_in user
  end

  describe "GET #index" do
    let(:function) { create(:function, workspace: workspace) }
    let(:agent_function) { create(:agent_function, agent: agent, function: function) }

    it "returns a success response" do
      get :index, params: { workspace_id: workspace.id, agent_id: agent.id }
      expect(response).to be_successful
    end

    it "assigns @agent_functions" do
      agent_function
      get :index, params: { workspace_id: workspace.id, agent_id: agent.id }
      expect(assigns(:agent_functions)).to include(agent_function)
    end

    it "assigns @available_functions" do
      available_function = create(:function, workspace: workspace)
      get :index, params: { workspace_id: workspace.id, agent_id: agent.id }
      expect(assigns(:available_functions)).to include(available_function)
    end

    it "assigns @workspace" do
      get :index, params: { workspace_id: workspace.id, agent_id: agent.id }
      expect(assigns(:workspace)).to eq(workspace)
    end

    it "assigns @agent" do
      get :index, params: { workspace_id: workspace.id, agent_id: agent.id }
      expect(assigns(:agent)).to eq(agent)
    end
  end

  describe "POST #create" do
    let(:function) { create(:function, workspace: workspace) }

    context "with valid params" do
      let(:valid_attributes) { { function_id: function.id } }

      it "creates a new AgentFunction" do
        expect {
          post :create, params: { workspace_id: workspace.id, agent_id: agent.id, agent_function: valid_attributes }
        }.to change(AgentFunction, :count).by(1)
      end

      it "redirects to agent functions index" do
        post :create, params: { workspace_id: workspace.id, agent_id: agent.id, agent_function: valid_attributes }
        expect(response).to redirect_to(workspace_agent_agent_functions_path(workspace, agent))
      end

      it "sets a success notice" do
        post :create, params: { workspace_id: workspace.id, agent_id: agent.id, agent_function: valid_attributes }
        expect(flash[:notice]).to eq("Function was successfully associated.")
      end
    end

    context "with invalid params" do
      let(:invalid_attributes) { { function_id: nil } }

      it "does not create a new AgentFunction" do
        expect {
          post :create, params: { workspace_id: workspace.id, agent_id: agent.id, agent_function: invalid_attributes }
        }.not_to change(AgentFunction, :count)
      end

      it "redirects to agent functions index with alert" do
        post :create, params: { workspace_id: workspace.id, agent_id: agent.id, agent_function: invalid_attributes }
        expect(response).to redirect_to(workspace_agent_agent_functions_path(workspace, agent))
        expect(flash[:alert]).to eq("Error associating function.")
      end
    end
  end

  describe "DELETE #destroy" do
    let(:function) { create(:function, workspace: workspace) }
    let(:agent_function) { create(:agent_function, agent: agent, function: function) }

    it "destroys the requested agent function" do
      agent_function
      expect {
        delete :destroy, params: { workspace_id: workspace.id, agent_id: agent.id, id: agent_function.id }
      }.to change(AgentFunction, :count).by(-1)
    end

    it "redirects to agent functions index" do
      delete :destroy, params: { workspace_id: workspace.id, agent_id: agent.id, id: agent_function.id }
      expect(response).to redirect_to(workspace_agent_agent_functions_path(workspace, agent))
    end

    it "sets a success notice" do
      delete :destroy, params: { workspace_id: workspace.id, agent_id: agent.id, id: agent_function.id }
      expect(flash[:notice]).to eq("Function association was removed.")
    end
  end

  context "when workspace is not found" do
    it "raises ActiveRecord::RecordNotFound" do
      expect {
        get :index, params: { workspace_id: 999999, agent_id: agent.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when agent is not found" do
    it "raises ActiveRecord::RecordNotFound" do
      expect {
        get :index, params: { workspace_id: workspace.id, agent_id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when agent function is not found" do
    it "raises ActiveRecord::RecordNotFound" do
      expect {
        delete :destroy, params: { workspace_id: workspace.id, agent_id: agent.id, id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
