class Workspace < ApplicationRecord
  validates :name, presence: true

  has_many :functions, dependent: :destroy
  has_many :llms, dependent: :destroy
  has_many :agents, dependent: :destroy
end
