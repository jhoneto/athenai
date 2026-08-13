require "rails_helper"

RSpec.describe Connector, type: :model do
  describe "validations" do
    subject { build(:connector) }

    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_one(:credential).class_name("Connector::Credential").dependent(:destroy) }
    it { is_expected.to have_many(:actions).class_name("Connector::Action").dependent(:destroy) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:account_id) }
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:kind).with_values(
        postgres: 0, mysql: 1, sqlserver: 2, oracle: 3,
        rest: 4, graphql: 5, openapi: 6,
        gmail: 7, microsoft365: 8, google_drive: 9, sharepoint: 10, s3: 11
      )
    }

    it { is_expected.to define_enum_for(:status).with_values(pending: 0, connected: 1, error: 2, disabled: 3) }
  end

  describe "#adapter" do
    it "resolves the HTTP adapter for a rest connector" do
      connector = build(:connector, kind: :rest)
      expect(connector.adapter).to be_a(Connector::Adapters::Http)
    end

    it "resolves the OpenApi adapter for an openapi connector" do
      connector = build(:connector, :openapi)
      expect(connector.adapter).to be_a(Connector::Adapters::OpenApi)
    end
  end
end
