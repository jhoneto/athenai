class Llm::Profile < ApplicationRecord
  self.table_name = "llm_profiles"

  belongs_to :llm_model, class_name: "Llm::Model", optional: true
  has_many :agents, dependent: :nullify

  enum :key, { fast: 0, balanced: 1, premium: 2, deep_reasoning: 3 }

  scope :active, -> { where(active: true) }
  scope :configured, -> { where.not(llm_model_id: nil) }

  validates :name, presence: true
  validates :credit_multiplier, numericality: { greater_than: 0 }
end
