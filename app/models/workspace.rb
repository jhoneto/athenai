class Workspace < ApplicationRecord
  validates :name, presence: true

  belongs_to :user
  has_many :user_workspaces, dependent: :destroy
  has_many :users, through: :user_workspaces
  has_many :functions, dependent: :destroy
  has_many :llms, dependent: :destroy
  has_many :agents, dependent: :destroy

  before_create :generate_api_credentials

  def shared_workspaces
    user.shared_workspaces
  end

  private

  def generate_api_credentials
    self.api_key = SecureRandom.hex(16)
    self.api_secret = SecureRandom.hex(32)
  end
end
