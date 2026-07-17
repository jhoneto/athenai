FactoryBot.define do
  factory :account_user do
    account
    user
    role { :member }

    trait :owner do
      role { :owner }
    end

    trait :admin do
      role { :admin }
    end
  end
end
