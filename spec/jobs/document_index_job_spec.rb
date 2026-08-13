require "rails_helper"

RSpec.describe DocumentIndexJob, type: :job do
  it "indexes the given document" do
    document = create(:document)
    indexer = instance_double(Document::Indexer, call: true)
    allow(Document::Indexer).to receive(:new).with(document).and_return(indexer)

    described_class.perform_now(document.id)

    expect(indexer).to have_received(:call)
  end
end
