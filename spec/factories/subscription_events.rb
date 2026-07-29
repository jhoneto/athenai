FactoryBot.define do
  factory :subscription_event do
    subscription
    event_type { "customer.subscription.created" }
    payload    { {} }
  end
end
