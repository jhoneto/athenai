FactoryBot.define do
  factory :document_chunk, class: "Document::Chunk" do
    document
    position { 0 }
    content { "Some chunk content." }
    embedding { Array.new(1536) { rand } }
  end
end
