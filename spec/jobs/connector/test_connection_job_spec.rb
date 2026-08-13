require "rails_helper"

RSpec.describe Connector::TestConnectionJob, type: :job do
  it "tests the connection for the given connector" do
    connector = create(:connector)
    adapter = instance_double(Connector::Adapters::Http, test_connection!: true)
    allow(Connector).to receive(:find).with(connector.id).and_return(connector)
    allow(connector).to receive(:adapter).and_return(adapter)

    described_class.perform_now(connector.id)

    expect(adapter).to have_received(:test_connection!)
  end
end
