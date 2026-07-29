class ResetMonthlyAnalysesJob < ApplicationJob
  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find_by(id: subscription_id)
    return unless subscription&.active?

    subscription.update!(analyses_used: 0)
  end
end
