class Workspace < ApplicationRecord
  validates :name, presence: true

  belongs_to :user
  has_many :user_workspaces, dependent: :destroy
  has_many :users, through: :user_workspaces
  has_many :functions, dependent: :destroy
  has_many :llms, dependent: :destroy
  has_many :agents, dependent: :destroy
end
