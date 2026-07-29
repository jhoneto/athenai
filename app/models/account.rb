class Account < ApplicationRecord
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_one  :subscription, dependent: :destroy

  validates :name, presence: true

  def feature?(name)
    subscription&.plan&.feature?(name) || false
  end
end
