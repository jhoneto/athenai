class Document < ApplicationRecord
  belongs_to :knowledge_base
  has_one_attached :file
  has_many :chunks, class_name: "Document::Chunk", dependent: :destroy

  enum :status, { pending: 0, processing: 1, indexed: 2, failed: 3 }

  validates :filename, presence: true

  def account
    knowledge_base.agent.account
  end
end
