class Webhooks::StripeController < ActionController::Base
  def create
    payload    = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    secret     = Rails.application.credentials.dig(:stripe, :webhook_secret)

    event = Stripe::Webhook.construct_event(payload, sig_header, secret)
    handle_event(event)
    render json: { received: true }
  rescue Stripe::SignatureVerificationError
    render json: { error: "Invalid signature" }, status: :bad_request
  rescue JSON::ParserError
    render json: { error: "Invalid payload" }, status: :bad_request
  end

  private

  def handle_event(event)
    case event.type
    when "customer.subscription.created", "customer.subscription.updated"
      sync_subscription(event.data.object)
    when "customer.subscription.deleted"
      cancel_subscription(event.data.object)
    when "invoice.payment_failed"
      mark_past_due(event.data.object)
    end

    log_event(event)
  end

  def sync_subscription(stripe_sub)
    subscription = find_subscription(stripe_sub)
    return unless subscription

    plan = Plan.find_by(stripe_price_id: stripe_sub.items.data.first&.price&.id)

    subscription.update!(
      stripe_subscription_id: stripe_sub.id,
      stripe_customer_id:     stripe_sub.customer,
      status:                 map_status(stripe_sub.status),
      plan:                   plan,
      current_period_start:   Time.zone.at(stripe_sub.current_period_start),
      current_period_end:     Time.zone.at(stripe_sub.current_period_end)
    )

    schedule_reset_job(subscription) if stripe_sub.status == "active"
  end

  def cancel_subscription(stripe_sub)
    find_subscription(stripe_sub)&.update!(status: :canceled)
  end

  def mark_past_due(invoice)
    Subscription.find_by(stripe_subscription_id: invoice.subscription)
                &.update!(status: :past_due)
  end

  def find_subscription(stripe_sub)
    account_id = stripe_sub.metadata["account_id"]
    return Subscription.find_by(account_id: account_id) if account_id.present?
    Subscription.find_by(stripe_subscription_id: stripe_sub.id)
  end

  def map_status(stripe_status)
    {
      "trialing"   => :trialing,
      "active"     => :active,
      "past_due"   => :past_due,
      "canceled"   => :canceled,
      "incomplete" => :incomplete
    }.fetch(stripe_status, :incomplete)
  end

  def schedule_reset_job(subscription)
    ResetMonthlyAnalysesJob.set(wait_until: subscription.current_period_end)
                           .perform_later(subscription.id)
  end

  def log_event(event)
    subscription = Subscription.find_by(
      stripe_subscription_id: event.data.object.try(:id)
    )
    return unless subscription

    subscription.subscription_events.create!(
      event_type:      event.type,
      stripe_event_id: event.id,
      payload:         event.data.object.to_h
    )
  end
end
