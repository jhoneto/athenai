class Llm < ApplicationRecord
  validates :name, presence: true
  validates :provider, presence: true
  validates :model, presence: true

  belongs_to :workspace
  has_many :agents, dependent: :destroy

  serialize :configs, coder: JSON
end
