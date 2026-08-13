require "rails_helper"

RSpec.describe "Docs", type: :request do
  it "renders the API documentation page for an authenticated user" do
    account = create(:account)
    user = create(:user)
    create(:account_user, account: account, user: user)
    sign_in user

    get docs_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Authorization: Bearer")
  end
end
