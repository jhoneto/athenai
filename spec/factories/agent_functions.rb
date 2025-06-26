FactoryBot.define do
  factory :agent_function do
    association :agent
    association :function
  end
end
