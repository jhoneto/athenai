require 'rails_helper'

RSpec.describe FunctionsController, type: :controller do
  let(:user) { create(:user) }
  let(:workspace) { create(:workspace) }
  let(:function) { create(:function, workspace: workspace) }

  before do
    workspace.user_workspaces.create!(user: user, access_functions: true, access_llm: true, access_agents: true)
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: { workspace_id: workspace.id }
      expect(response).to be_successful
    end

    it "assigns @functions" do
      function
      get :index, params: { workspace_id: workspace.id }
      expect(assigns(:functions)).to include(function)
    end

    it "assigns @workspace" do
      get :index, params: { workspace_id: workspace.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { workspace_id: workspace.id, id: function.id }
      expect(response).to be_successful
    end

    it "assigns @function" do
      get :show, params: { workspace_id: workspace.id, id: function.id }
      expect(assigns(:function)).to eq(function)
    end

    it "assigns @workspace" do
      get :show, params: { workspace_id: workspace.id, id: function.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: { workspace_id: workspace.id }
      expect(response).to be_successful
    end

    it "assigns @function" do
      get :new, params: { workspace_id: workspace.id }
      expect(assigns(:function)).to be_a_new(Function)
    end

    it "assigns @workspace" do
      get :new, params: { workspace_id: workspace.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { workspace_id: workspace.id, id: function.id }
      expect(response).to be_successful
    end

    it "assigns @function" do
      get :edit, params: { workspace_id: workspace.id, id: function.id }
      expect(assigns(:function)).to eq(function)
    end

    it "assigns @workspace" do
      get :edit, params: { workspace_id: workspace.id, id: function.id }
      expect(assigns(:workspace)).to eq(workspace)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) {
      {
        name: "Test Function",
        code: "def test_function\n  puts 'Hello World'\nend",
        description: "Test function description",
        parameters: {
          "0" => {
            "name" => "input",
            "type" => "string",
            "required" => "true",
            "description" => "Input parameter"
          }
        },
        tool_type: "custom",
        enabled: true
      }
    }

    let(:invalid_attributes) {
      {
        name: "",
        code: "",
        description: "",
        parameters: {},
        tool_type: ""
      }
    }

    context "with valid params" do
      it "creates a new Function" do
        expect {
          post :create, params: { workspace_id: workspace.id, function: valid_attributes }
        }.to change(Function, :count).by(1)
      end

      it "redirects to the created function" do
        post :create, params: { workspace_id: workspace.id, function: valid_attributes }
        expect(response).to redirect_to([ workspace, Function.last ])
      end

      it "sets a success notice" do
        post :create, params: { workspace_id: workspace.id, function: valid_attributes }
        expect(flash[:notice]).to eq("Function was successfully created.")
      end
    end

    context "with invalid params" do
      it "does not create a new Function" do
        expect {
          post :create, params: { workspace_id: workspace.id, function: invalid_attributes }
        }.not_to change(Function, :count)
      end

      it "renders the new template" do
        post :create, params: { workspace_id: workspace.id, function: invalid_attributes }
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    let(:new_attributes) {
      {
        name: "Updated Function",
        code: "def updated_function\n  puts 'Updated'\nend",
        description: "Updated description"
      }
    }

    let(:invalid_attributes) {
      {
        name: "",
        code: "",
        description: ""
      }
    }

    context "with valid params" do
      it "updates the requested function" do
        put :update, params: { workspace_id: workspace.id, id: function.id, function: new_attributes }
        function.reload
        expect(function.name).to eq("Updated Function")
        expect(function.code).to eq("def updated_function\n  puts 'Updated'\nend")
      end

      it "redirects to the function" do
        put :update, params: { workspace_id: workspace.id, id: function.id, function: new_attributes }
        function.reload
        expect(response).to redirect_to([ workspace, function ])
      end

      it "sets a success notice" do
        put :update, params: { workspace_id: workspace.id, id: function.id, function: new_attributes }
        expect(flash[:notice]).to eq("Function was successfully updated.")
      end
    end

    context "with invalid params" do
      it "renders the edit template" do
        put :update, params: { workspace_id: workspace.id, id: function.id, function: invalid_attributes }
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested function" do
      function
      expect {
        delete :destroy, params: { workspace_id: workspace.id, id: function.id }
      }.to change(Function, :count).by(-1)
    end

    it "redirects to the functions list" do
      delete :destroy, params: { workspace_id: workspace.id, id: function.id }
      expect(response).to redirect_to(workspace_functions_url(workspace))
    end

    it "sets a success notice" do
      delete :destroy, params: { workspace_id: workspace.id, id: function.id }
      expect(flash[:notice]).to eq("Function was successfully deleted.")
    end
  end

  context "when workspace is not found" do
    it "raises ActiveRecord::RecordNotFound" do
      expect {
        get :index, params: { workspace_id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when function is not found" do
    it "raises ActiveRecord::RecordNotFound" do
      expect {
        get :show, params: { workspace_id: workspace.id, id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
