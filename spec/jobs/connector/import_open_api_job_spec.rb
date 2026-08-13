require "rails_helper"

RSpec.describe Connector::ImportOpenApiJob, type: :job do
  it "imports actions for the given connector" do
    connector = create(:connector, :openapi)
    importer = instance_double(Connector::OpenApiImporter, call: true)
    allow(Connector).to receive(:find).with(connector.id).and_return(connector)
    allow(Connector::OpenApiImporter).to receive(:new).with(connector).and_return(importer)

    described_class.perform_now(connector.id)

    expect(importer).to have_received(:call)
  end
end
