FactoryBot.define do
  factory :plan do
    sequence(:name) { |n| "Plan #{n}" }
    sequence(:slug) { |n| "plan-#{n}" }
    analyses_per_month { 50 }
    price_cents        { 29_700 }
    active             { true }

    trait :starter do
      name               { "Starter" }
      slug               { "starter" }
      analyses_per_month { 50 }
      price_cents        { 29_700 }
    end

    trait :growth do
      name               { "Growth" }
      slug               { "growth" }
      analyses_per_month { 300 }
      price_cents        { 79_700 }
    end

    trait :enterprise do
      name               { "Enterprise" }
      slug               { "enterprise" }
      analyses_per_month { nil }
      price_cents        { 0 }
    end
  end
end
