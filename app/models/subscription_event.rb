class SubscriptionEvent < ApplicationRecord
  belongs_to :subscription

  validates :event_type, presence: true
end
