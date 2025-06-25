class Function < ApplicationRecord
  validates :name, presence: true
  validates :code, presence: true

  belongs_to :workspace
  has_many :agent_functions, dependent: :destroy
  has_many :agents, through: :agent_functions
end