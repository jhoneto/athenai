require 'rails_helper'

RSpec.describe AgentsController, type: :controller do
  let(:user) { create(:user) }
  let(:workspace) { create(:workspace, user: user) }

  before do
    sign_in user
  end

  describe "GET #index" do
    let(:llm) { create(:llm, workspace: workspace) }
    let(:agent) { create(:agent, workspace: workspace, llm: llm) }

    it "returns a success response" do
      get :index, params: { workspace_id: workspace.id }
      expect(response).to be_successful
    end

    it "assigns @agents" do
      agent
      get :index, params: { workspace_id: workspace.id }
      expect(assigns(:agents)).to include(agent)
    end

    it "assigns @workspace" do
      get :index, params: { workspace_id: workspace.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "GET #show" do
    let(:llm) { create(:llm, workspace: workspace) }
    let(:agent) { create(:agent, workspace: workspace, llm: llm) }

    it "returns a success response" do
      get :show, params: { workspace_id: workspace.id, id: agent.id }
      expect(response).to be_successful
    end

    it "assigns @agent" do
      get :show, params: { workspace_id: workspace.id, id: agent.id }
      expect(assigns(:agent)).to eq(agent)
    end

    it "assigns @workspace" do
      get :show, params: { workspace_id: workspace.id, id: agent.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "GET #new" do
    let(:llm) { create(:llm, workspace: workspace) }

    it "returns a success response" do
      get :new, params: { workspace_id: workspace.id }
      expect(response).to be_successful
    end

    it "assigns @agent" do
      get :new, params: { workspace_id: workspace.id }
      expect(assigns(:agent)).to be_a_new(Agent)
    end

    it "assigns @llms" do
      llm
      get :new, params: { workspace_id: workspace.id }
      expect(assigns(:llms)).to include(llm)
    end

    it "assigns @workspace" do
      get :new, params: { workspace_id: workspace.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "GET #edit" do
    let(:llm) { create(:llm, workspace: workspace) }
    let(:agent) { create(:agent, workspace: workspace, llm: llm) }

    it "returns a success response" do
      get :edit, params: { workspace_id: workspace.id, id: agent.id }
      expect(response).to be_successful
    end

    it "assigns @agent" do
      get :edit, params: { workspace_id: workspace.id, id: agent.id }
      expect(assigns(:agent)).to eq(agent)
    end

    it "assigns @llms" do
      get :edit, params: { workspace_id: workspace.id, id: agent.id }
      expect(assigns(:llms)).to include(llm)
    end

    it "assigns @workspace" do
      get :edit, params: { workspace_id: workspace.id, id: agent.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "POST #create" do
    let(:llm) { create(:llm, workspace: workspace) }

    context "with valid params" do
      let(:valid_attributes) { { name: "Test Agent", prompt: "Test prompt", llm_id: llm.id } }

      it "creates a new Agent" do
        expect {
          post :create, params: { workspace_id: workspace.id, agent: valid_attributes }
        }.to change(Agent, :count).by(1)
      end

      it "redirects to the created agent" do
        post :create, params: { workspace_id: workspace.id, agent: valid_attributes }
        expect(response).to redirect_to([ workspace, Agent.last ])
      end

      it "sets a success notice" do
        post :create, params: { workspace_id: workspace.id, agent: valid_attributes }
        expect(flash[:notice]).to eq("Agent was successfully created.")
      end
    end

    context "with invalid params" do
      let(:invalid_attributes) { { name: "", prompt: "", llm_id: nil } }

      it "does not create a new Agent" do
        expect {
          post :create, params: { workspace_id: workspace.id, agent: invalid_attributes }
        }.not_to change(Agent, :count)
      end

      it "renders the new template" do
        post :create, params: { workspace_id: workspace.id, agent: invalid_attributes }
        expect(response).to render_template("new")
      end

      it "assigns @llms" do
        post :create, params: { workspace_id: workspace.id, agent: invalid_attributes }
        expect(assigns(:llms)).to eq(workspace.llms)
      end
    end
  end

  describe "PUT #update" do
    let(:llm) { create(:llm, workspace: workspace) }
    let(:agent) { create(:agent, workspace: workspace, llm: llm) }

    context "with valid params" do
      let(:new_attributes) { { name: "Updated Agent", prompt: "Updated prompt" } }

      it "updates the requested agent" do
        put :update, params: { workspace_id: workspace.id, id: agent.id, agent: new_attributes }
        agent.reload
        expect(agent.name).to eq("Updated Agent")
        expect(agent.prompt).to eq("Updated prompt")
      end

      it "redirects to the agent" do
        put :update, params: { workspace_id: workspace.id, id: agent.id, agent: new_attributes }
        agent.reload
        expect(response).to redirect_to([ workspace, agent ])
      end

      it "sets a success notice" do
        put :update, params: { workspace_id: workspace.id, id: agent.id, agent: new_attributes }
        expect(flash[:notice]).to eq("Agent was successfully updated.")
      end
    end

    context "with invalid params" do
      let(:invalid_attributes) { { name: "", prompt: "" } }

      it "renders the edit template" do
        put :update, params: { workspace_id: workspace.id, id: agent.id, agent: invalid_attributes }
        expect(response).to render_template("edit")
      end

      it "assigns @llms" do
        put :update, params: { workspace_id: workspace.id, id: agent.id, agent: invalid_attributes }
        expect(assigns(:llms)).to eq(workspace.llms)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:llm) { create(:llm, workspace: workspace) }
    let(:agent) { create(:agent, workspace: workspace, llm: llm) }

    it "destroys the requested agent" do
      agent
      expect {
        delete :destroy, params: { workspace_id: workspace.id, id: agent.id }
      }.to change(Agent, :count).by(-1)
    end

    it "redirects to the agents list" do
      delete :destroy, params: { workspace_id: workspace.id, id: agent.id }
      expect(response).to redirect_to(workspace_agents_url(workspace))
    end

    it "sets a success notice" do
      delete :destroy, params: { workspace_id: workspace.id, id: agent.id }
      expect(flash[:notice]).to eq("Agent was successfully deleted.")
    end
  end

  context "when workspace is not found" do
    it "raises ActiveRecord::RecordNotFound" do
      expect {
        get :index, params: { workspace_id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when agent is not found" do
    it "raises ActiveRecord::RecordNotFound" do
      expect {
        get :show, params: { workspace_id: workspace.id, id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
