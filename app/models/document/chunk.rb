class Document::Chunk < ApplicationRecord
  self.table_name = "document_chunks"

  belongs_to :document

  has_neighbors :embedding

  validates :content, presence: true
end
