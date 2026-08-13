class KnowledgeBase < ApplicationRecord
  belongs_to :agent
  has_many :documents, dependent: :destroy
end
