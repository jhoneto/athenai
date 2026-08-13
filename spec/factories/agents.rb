FactoryBot.define do
  factory :agent do
    account
    sequence(:name) { |n| "Agent #{n}" }
    system_prompt { "You are a helpful assistant." }
    temperature { 0.7 }
    status { :draft }

    trait :published do
      status { :published }
      llm_profile { Llm::Profile.find_by(key: :fast) || create(:llm_profile) }
    end
  end
end
