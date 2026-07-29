FactoryBot.define do
  factory :subscription do
    account
    status               { :trialing }
    trial_analyses_total { 5 }
    trial_analyses_used  { 0 }
    analyses_used        { 0 }

    trait :trialing do
      status { :trialing }
      plan   { nil }
    end

    trait :active do
      status { :active }
      plan
      current_period_start { Time.current }
      current_period_end   { 1.month.from_now }
    end

    trait :past_due do
      status { :past_due }
      plan
    end

    trait :canceled do
      status { :canceled }
      plan
    end

    trait :exhausted_trial do
      status               { :trialing }
      trial_analyses_used  { 5 }
      trial_analyses_total { 5 }
    end
  end
end
