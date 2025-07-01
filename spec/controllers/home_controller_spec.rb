require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  let(:user) { create(:user) }

  describe "GET #index" do
    context "when user is authenticated" do
      before do
        sign_in user
      end

      it "returns a success response" do
        get :index
        expect(response).to be_successful
      end

      it "renders the index template" do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
