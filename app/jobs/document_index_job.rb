class DocumentIndexJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    Document::Indexer.new(Document.find(document_id)).call
  end
end
