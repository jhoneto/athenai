require 'rails_helper'

RSpec.describe WorkspacesController, type: :controller do
  let(:user) { create(:user) }
  let(:workspace) { create(:workspace, user: user) }

  before do
    sign_in user
  end

  describe "GET #index" do
    it "redirects to root path" do
      get :index
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET #show" do
    context "when user is the owner of workspace" do
      it "returns a success response" do
        get :show, params: { id: workspace.id }
        expect(response).to be_successful
      end

      it "assigns @workspace" do
        get :show, params: { id: workspace.id }
        expect(assigns(:workspace)).to eq(workspace)
      end
    end

    context "when user has shared access to workspace" do
      let(:other_user_workspace) { create(:workspace) }

      before do
        create(:user_workspace, user: user, workspace: other_user_workspace, access_llm: true)
      end

      it "returns a success response" do
        get :show, params: { id: other_user_workspace.id }
        expect(response).to be_successful
      end

      it "assigns @workspace" do
        get :show, params: { id: other_user_workspace.id }
        expect(assigns(:workspace)).to eq(other_user_workspace)
      end
    end

    context "when user does not have access to workspace" do
      let(:other_workspace) { create(:workspace) }

      it "redirects to root path" do
        get :show, params: { id: other_workspace.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns @workspace" do
      get :new
      expect(assigns(:workspace)).to be_a_new(Workspace)
    end
  end

  describe "GET #edit" do
    context "when user is the owner of workspace" do
      it "returns a success response" do
        get :edit, params: { id: workspace.id }
        expect(response).to be_successful
      end

      it "assigns @workspace" do
        get :edit, params: { id: workspace.id }
        expect(assigns(:workspace)).to eq(workspace)
      end
    end

    context "when user does not have access to workspace" do
      let(:other_workspace) { create(:workspace) }

      it "redirects to root path" do
        get :edit, params: { id: other_workspace.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_attributes) {
      {
        name: "Test Workspace"
      }
    }

    let(:invalid_attributes) {
      {
        name: ""
      }
    }

    context "with valid params" do
      it "creates a new Workspace" do
        expect {
          post :create, params: { workspace: valid_attributes }
        }.to change(Workspace, :count).by(1)
      end

      it "sets the current user as the workspace owner" do
        post :create, params: { workspace: valid_attributes }
        expect(Workspace.last.user).to eq(user)
      end

      it "redirects to the created workspace" do
        post :create, params: { workspace: valid_attributes }
        expect(response).to redirect_to(Workspace.last)
      end

      it "sets a success notice" do
        post :create, params: { workspace: valid_attributes }
        expect(flash[:notice]).to eq("Workspace was successfully created.")
      end
    end

    context "with invalid params" do
      it "does not create a new Workspace" do
        expect {
          post :create, params: { workspace: invalid_attributes }
        }.not_to change(Workspace, :count)
      end

      it "renders the new template" do
        post :create, params: { workspace: invalid_attributes }
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    let(:new_attributes) {
      {
        name: "Updated Workspace"
      }
    }

    let(:invalid_attributes) {
      {
        name: ""
      }
    }

    context "when user is the owner of workspace" do
      context "with valid params" do
        it "updates the requested workspace" do
          put :update, params: { id: workspace.id, workspace: new_attributes }
          workspace.reload
          expect(workspace.name).to eq("Updated Workspace")
        end

        it "redirects to the workspace" do
          put :update, params: { id: workspace.id, workspace: new_attributes }
          workspace.reload
          expect(response).to redirect_to(workspace)
        end

        it "sets a success notice" do
          put :update, params: { id: workspace.id, workspace: new_attributes }
          expect(flash[:notice]).to eq("Workspace was successfully updated.")
        end
      end

      context "with invalid params" do
        it "renders the edit template" do
          put :update, params: { id: workspace.id, workspace: invalid_attributes }
          expect(response).to render_template("edit")
        end
      end
    end

    context "when user does not have access to workspace" do
      let(:other_workspace) { create(:workspace) }

      it "redirects to root path" do
        put :update, params: { id: other_workspace.id, workspace: new_attributes }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when user is the owner of workspace" do
      it "destroys the requested workspace" do
        workspace
        expect {
          delete :destroy, params: { id: workspace.id }
        }.to change(Workspace, :count).by(-1)
      end

      it "redirects to the workspaces list" do
        delete :destroy, params: { id: workspace.id }
        expect(response).to redirect_to(workspaces_url)
      end

      it "sets a success notice" do
        delete :destroy, params: { id: workspace.id }
        expect(flash[:notice]).to eq("Workspace was successfully deleted.")
      end
    end

    context "when user does not have access to workspace" do
      let(:other_workspace) { create(:workspace) }

      it "redirects to root path" do
        delete :destroy, params: { id: other_workspace.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  context "when workspace is not found" do
    it "raises ActiveRecord::RecordNotFound" do
      expect {
        get :show, params: { id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
