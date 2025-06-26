class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true

  has_many :workspaces, dependent: :destroy
  has_many :user_workspaces, dependent: :destroy
  has_many :shared_workspaces, through: :user_workspaces, source: :workspace
end
