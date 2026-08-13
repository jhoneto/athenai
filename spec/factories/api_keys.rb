FactoryBot.define do
  factory :api_key do
    account
    sequence(:name) { |n| "API Key #{n}" }
    sequence(:prefix) { |n| "ath_live_test#{n}" }
    token_digest { Digest::SHA256.hexdigest(SecureRandom.hex(24)) }
  end
end
