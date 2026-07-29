class CreateStripeCustomerJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    account = Account.find_by(id: account_id)
    return unless account
    return if account.subscription&.stripe_customer_id.present?

    Subscription::StripeCheckout.new(account).send(:ensure_customer_id)
  end
end
