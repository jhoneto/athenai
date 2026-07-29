class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  attr_accessor :account_name

  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users

  validates :name, presence: true
end
