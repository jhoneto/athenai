require 'rails_helper'

RSpec.describe "Homes", type: :request do
  describe "GET /index" do
    context "when user is authenticated" do
      let(:user) { create(:user) }

      before do
        # Login the user through session
        post user_session_path, params: {
          user: {
            email: user.email,
            password: user.password
          }
        }
      end

      it "returns http success" do
        get "/home/index"
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not authenticated" do
      it "redirects to login page" do
        get "/home/index"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /" do
    context "when user is authenticated" do
      let(:user) { create(:user) }

      before do
        # Login the user through session
        post user_session_path, params: {
          user: {
            email: user.email,
            password: user.password
          }
        }
      end

      it "returns http success" do
        get "/"
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not authenticated" do
      it "redirects to login page" do
        get "/"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
