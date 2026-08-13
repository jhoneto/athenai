require "rails_helper"

RSpec.describe Connector::Credential, type: :model do
  describe "validations" do
    subject { build(:connector_credential) }

    it { is_expected.to belong_to(:connector) }
    it { is_expected.to validate_presence_of(:encrypted_secrets) }
  end

  it "encrypts the secrets at rest" do
    credential = create(:connector_credential, encrypted_secrets: { "api_key" => "super-secret" })

    raw_value = ActiveRecord::Base.connection.select_value(
      "SELECT encrypted_secrets FROM connector_credentials WHERE id = #{credential.id}"
    )

    expect(raw_value).not_to include("super-secret")
    expect(credential.reload.encrypted_secrets).to eq("api_key" => "super-secret")
  end
end
