require "rails_helper"

RSpec.describe Document::Search, type: :model do
  def one_hot(index)
    Array.new(1536, 0.0).tap { |vector| vector[index] = 1.0 }
  end

  it "returns the chunks nearest to the query embedding, scoped to the knowledge base's indexed documents" do
    knowledge_base = create(:knowledge_base)
    document = create(:document, knowledge_base: knowledge_base, status: :indexed)
    other_document = create(:document, status: :indexed)

    near  = create(:document_chunk, document: document, position: 0, embedding: one_hot(0))
    far   = create(:document_chunk, document: document, position: 1, embedding: one_hot(1))
    other = create(:document_chunk, document: other_document, embedding: one_hot(0))

    allow(RubyLLM).to receive(:embed).and_return(double(vectors: one_hot(0)))

    results = described_class.new(knowledge_base).call("query")

    expect(results).to eq([ near, far ])
    expect(results).not_to include(other)
  end

  it "excludes chunks that belong to documents that are not indexed" do
    knowledge_base = create(:knowledge_base)
    pending_document = create(:document, knowledge_base: knowledge_base, status: :pending)
    chunk = create(:document_chunk, document: pending_document, embedding: one_hot(0))

    allow(RubyLLM).to receive(:embed).and_return(double(vectors: one_hot(0)))

    expect(described_class.new(knowledge_base).call("query")).not_to include(chunk)
  end
end
