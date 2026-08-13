class Document::Search
  def initialize(knowledge_base)
    @knowledge_base = knowledge_base
  end

  def call(query, limit: 5)
    embedding = RubyLLM.embed(query).vectors
    Document::Chunk
      .joins(:document)
      .where(documents: { knowledge_base_id: @knowledge_base.id, status: :indexed })
      .nearest_neighbors(:embedding, embedding, distance: "cosine")
      .limit(limit)
  end
end
