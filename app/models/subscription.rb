class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :plan, optional: true
  has_many :subscription_events, dependent: :destroy

  enum :status, {
    trialing:   0,
    active:     1,
    past_due:   2,
    canceled:   3,
    incomplete: 4
  }

  validates :account_id, uniqueness: true
  validates :trial_analyses_total, :trial_analyses_used, :analyses_used,
            numericality: { greater_than_or_equal_to: 0 }

  def analyses_remaining
    if trialing?
      trial_analyses_total - trial_analyses_used
    elsif plan&.unlimited?
      Float::INFINITY
    else
      (plan&.analyses_per_month || 0) - analyses_used
    end
  end

  def can_analyze?
    if trialing?
      trial_analyses_used < trial_analyses_total
    else
      active? && analyses_remaining > 0
    end
  end

  def record_analysis!
    if trialing?
      increment!(:trial_analyses_used)
    else
      increment!(:analyses_used)
    end
  end

  def quota_percentage
    return 0 if trialing?
    return 0 if plan&.unlimited?
    total = plan.analyses_per_month
    return 100 if total.zero?
    [(analyses_used.to_f / total * 100).round, 100].min
  end

  def trial_quota_percentage
    return 0 unless trialing?
    [(trial_analyses_used.to_f / trial_analyses_total * 100).round, 100].min
  end
end
