class Subscription::StripeCheckout
  def initialize(account, plan = nil)
    @account = account
    @plan    = plan
  end

  def checkout_url(success_url:, cancel_url:)
    session = Stripe::Checkout::Session.create(
      customer:          ensure_customer_id,
      mode:              "subscription",
      line_items:        [{ price: @plan.stripe_price_id, quantity: 1 }],
      success_url:       success_url,
      cancel_url:        cancel_url,
      metadata:          { account_id: @account.id, plan_id: @plan.id },
      subscription_data: { metadata: { account_id: @account.id } }
    )
    session.url
  end

  def portal_url(return_url:)
    Stripe::BillingPortal::Session.create(
      customer:   ensure_customer_id,
      return_url: return_url
    ).url
  end

  private

  def ensure_customer_id
    sub = @account.subscription
    return sub.stripe_customer_id if sub&.stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email:    @account.users.first&.email,
      name:     @account.name,
      metadata: { account_id: @account.id }
    )
    sub&.update!(stripe_customer_id: customer.id)
    customer.id
  end
end
