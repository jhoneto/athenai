require "rails_helper"

RSpec.describe Connector::OpenApiImporter, type: :model do
  let(:connector) { create(:connector, :openapi) }
  let(:spec_body) { File.read(Rails.root.join("spec/fixtures/files/openapi_sample.json")) }

  before do
    stub_request(:get, connector.config["spec_url"]).to_return(status: 200, body: spec_body)
  end

  it "creates a Connector::Action for each operation in the spec" do
    described_class.new(connector).call

    expect(connector.actions.pluck(:name)).to contain_exactly("listUsers", "createUser", "get_/health")
  end

  it "derives the input schema and definition from the operation" do
    described_class.new(connector).call

    action = connector.actions.find_by(name: "listUsers")
    expect(action.input_schema).to eq("type" => "object", "properties" => { "limit" => { "type" => "integer" } })
    expect(action.definition).to eq("method" => "get", "path" => "/users")
    expect(action).to be_http_call
  end

  it "does not duplicate actions when reimporting" do
    2.times { described_class.new(connector).call }

    expect(connector.actions.count).to eq(3)
  end
end
