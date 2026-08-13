require "rails_helper"

RSpec.describe Connector::Action, type: :model do
  describe "validations" do
    subject { build(:connector_action) }

    it { is_expected.to belong_to(:connector) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:connector_id) }
    it { is_expected.to validate_presence_of(:input_schema) }
    it { is_expected.to validate_presence_of(:definition) }
  end

  describe "enum" do
    it { is_expected.to define_enum_for(:kind).with_values(query: 0, http_call: 1, graphql_call: 2, file_search: 3) }
  end
end
