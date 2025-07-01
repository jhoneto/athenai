require 'rails_helper'

RSpec.describe LlmsController, type: :controller do
  let(:user) { create(:user) }
  let(:workspace) { create(:workspace) }
  let(:llm) { create(:llm, workspace: workspace) }

  before do
    workspace.users << user
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: { workspace_id: workspace.id }
      expect(response).to be_successful
    end

    it "assigns @llms" do
      llm
      get :index, params: { workspace_id: workspace.id }
      expect(assigns(:llms)).to include(llm)
    end

    it "assigns @workspace" do
      get :index, params: { workspace_id: workspace.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { workspace_id: workspace.id, id: llm.id }
      expect(response).to be_successful
    end

    it "assigns @llm" do
      get :show, params: { workspace_id: workspace.id, id: llm.id }
      expect(assigns(:llm)).to eq(llm)
    end

    it "assigns @workspace" do
      get :show, params: { workspace_id: workspace.id, id: llm.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: { workspace_id: workspace.id }
      expect(response).to be_successful
    end

    it "assigns @llm" do
      get :new, params: { workspace_id: workspace.id }
      expect(assigns(:llm)).to be_a_new(Llm)
    end

    it "assigns @workspace" do
      get :new, params: { workspace_id: workspace.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { workspace_id: workspace.id, id: llm.id }
      expect(response).to be_successful
    end

    it "assigns @llm" do
      get :edit, params: { workspace_id: workspace.id, id: llm.id }
      expect(assigns(:llm)).to eq(llm)
    end

    it "assigns @workspace" do
      get :edit, params: { workspace_id: workspace.id, id: llm.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) {
      {
        name: "Test LLM",
        provider: "OpenAI",
        model: "gpt-3.5-turbo",
        api_key: "test-api-key",
        temperature: 0.7,
        max_tokens: 1000
      }
    }

    let(:invalid_attributes) {
      {
        name: "",
        provider: "",
        model: "",
        api_key: ""
      }
    }

    context "with valid params" do
      it "creates a new Llm" do
        expect {
          post :create, params: { workspace_id: workspace.id, llm: valid_attributes }
        }.to change(Llm, :count).by(1)
      end

      it "redirects to the created llm" do
        post :create, params: { workspace_id: workspace.id, llm: valid_attributes }
        expect(response).to redirect_to([ workspace, Llm.last ])
      end

      it "sets a success notice" do
        post :create, params: { workspace_id: workspace.id, llm: valid_attributes }
        expect(flash[:notice]).to eq("LLM was successfully created.")
      end
    end

    context "with invalid params" do
      it "does not create a new Llm" do
        expect {
          post :create, params: { workspace_id: workspace.id, llm: invalid_attributes }
        }.not_to change(Llm, :count)
      end

      it "renders the new template" do
        post :create, params: { workspace_id: workspace.id, llm: invalid_attributes }
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    let(:new_attributes) {
      {
        name: "Updated LLM",
        temperature: 0.9,
        max_tokens: 2000
      }
    }

    let(:invalid_attributes) {
      {
        name: "",
        provider: ""
      }
    }

    context "with valid params" do
      it "updates the requested llm" do
        put :update, params: { workspace_id: workspace.id, id: llm.id, llm: new_attributes }
        llm.reload
        expect(llm.name).to eq("Updated LLM")
        expect(llm.temperature.to_f).to eq(0.9)
        expect(llm.max_tokens.to_i).to eq(2000)
      end

      it "redirects to the llm" do
        put :update, params: { workspace_id: workspace.id, id: llm.id, llm: new_attributes }
        llm.reload
        expect(response).to redirect_to([ workspace, llm ])
      end

      it "sets a success notice" do
        put :update, params: { workspace_id: workspace.id, id: llm.id, llm: new_attributes }
        expect(flash[:notice]).to eq("LLM was successfully updated.")
      end
    end

    context "with invalid params" do
      it "renders the edit template" do
        put :update, params: { workspace_id: workspace.id, id: llm.id, llm: invalid_attributes }
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested llm" do
      llm
      expect {
        delete :destroy, params: { workspace_id: workspace.id, id: llm.id }
      }.to change(Llm, :count).by(-1)
    end

    it "redirects to the llms list" do
      delete :destroy, params: { workspace_id: workspace.id, id: llm.id }
      expect(response).to redirect_to(workspace_llms_url(workspace))
    end

    it "sets a success notice" do
      delete :destroy, params: { workspace_id: workspace.id, id: llm.id }
      expect(flash[:notice]).to eq("LLM was successfully deleted.")
    end
  end

  context "when workspace is not found" do
    it "raises ActiveRecord::RecordNotFound" do
      expect {
        get :index, params: { workspace_id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when llm is not found" do
    it "raises ActiveRecord::RecordNotFound" do
      expect {
        get :show, params: { workspace_id: workspace.id, id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
