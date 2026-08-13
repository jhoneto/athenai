class Document::Indexer
  CHUNK_SIZE = 1_000
  BATCH_SIZE = 100

  def initialize(document)
    @document = document
  end

  def call
    @document.update!(status: :processing)
    chunks = extract_text.scan(/.{1,#{CHUNK_SIZE}}/m)

    chunks.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
      embeddings = RubyLLM.embed(batch).vectors

      batch.each_with_index do |content, index|
        position = (batch_index * BATCH_SIZE) + index
        @document.chunks.create!(position: position, content: content, embedding: embeddings[index])
      end
    end

    @document.update!(status: :indexed)
  rescue => e
    @document.update!(status: :failed, error: e.message)
  end

  private

  def extract_text
    @document.file.download.force_encoding(Encoding::UTF_8).scrub.delete("\u0000")
  end
end
