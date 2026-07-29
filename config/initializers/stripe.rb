Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
Stripe.api_version = "2025-06-30.basil"
