class Agent < ApplicationRecord
  validates :name, presence: true
  validates :prompt, presence: true

  belongs_to :workspace
  belongs_to :llm
  has_many :agent_functions, dependent: :destroy
  has_many :functions, through: :agent_functions
end