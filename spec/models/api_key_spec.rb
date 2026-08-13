require "rails_helper"

RSpec.describe ApiKey, type: :model do
  describe "validations" do
    subject { build(:api_key) }

    it { is_expected.to belong_to(:account) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe ".create_with_token!" do
    it "returns the persisted key and the full token, in that order" do
      account = create(:account)

      key, token = ApiKey.create_with_token!(account: account, name: "CI")

      expect(key).to be_persisted
      expect(token).to eq("#{key.prefix}.#{token.split('.').last}")
    end

    it "never persists the raw token" do
      account = create(:account)

      _key, token = ApiKey.create_with_token!(account: account, name: "CI")
      raw_token = token.split(".").last

      expect(ApiKey.pluck(:token_digest)).not_to include(raw_token)
    end
  end

  describe ".authenticate" do
    it "returns the matching active key for a valid token" do
      account = create(:account)
      key, token = ApiKey.create_with_token!(account: account, name: "CI")

      expect(ApiKey.authenticate(token)).to eq(key)
    end

    it "returns nil for an unknown token" do
      expect(ApiKey.authenticate("ath_live_bogus.deadbeef")).to be_nil
    end

    it "returns nil for a malformed token" do
      expect(ApiKey.authenticate("not-a-real-token")).to be_nil
    end

    it "returns nil for a blank token" do
      expect(ApiKey.authenticate(nil)).to be_nil
    end

    it "returns nil for a revoked key" do
      account = create(:account)
      key, token = ApiKey.create_with_token!(account: account, name: "CI")
      key.revoke!

      expect(ApiKey.authenticate(token)).to be_nil
    end
  end

  describe "#revoke!" do
    it "sets revoked_at" do
      key = create(:api_key)

      expect { key.revoke! }.to change { key.reload.revoked_at }.from(nil)
    end
  end
end
