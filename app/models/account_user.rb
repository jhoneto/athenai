class AccountUser < ApplicationRecord
  belongs_to :account
  belongs_to :user

  enum :role, { owner: 0, admin: 1, member: 2 }

  validates :user_id, uniqueness: { scope: :account_id }
end
