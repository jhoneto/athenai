class Account < ApplicationRecord
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_one  :subscription, dependent: :destroy
  has_many :agents, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :llm_credentials, class_name: "Llm::Credential", dependent: :destroy
  has_many :connectors, dependent: :destroy
  has_many :api_keys, dependent: :destroy

  validates :name, presence: true

  def feature?(name)
    subscription&.plan&.feature?(name) || false
  end
end
