FactoryBot.define do
  factory :agent do
    account
    sequence(:name) { |n| "Agent #{n}" }
    system_prompt { "You are a helpful assistant." }
    temperature { 0.7 }
    status { :draft }
  end
end
