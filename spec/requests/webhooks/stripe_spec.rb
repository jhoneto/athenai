require "rails_helper"

RSpec.describe "Webhooks::Stripe", type: :request do
  describe "POST /webhooks/stripe" do
    context "with invalid signature" do
      it "returns 400 bad request" do
        post webhooks_stripe_path,
             params: "{}",
             headers: {
               "HTTP_STRIPE_SIGNATURE" => "invalid_sig",
               "CONTENT_TYPE"          => "application/json"
             }

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Invalid signature")
      end
    end

    context "with malformed JSON" do
      it "returns 400 bad request" do
        post webhooks_stripe_path,
             params: "not-json",
             headers: {
               "CONTENT_TYPE" => "application/json"
             }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
