FactoryBot.define do
  factory :user_workspace do
    user { nil }
    workspace { nil }
    access_llm { false }
    access_agents { false }
    access_functions { false }
  end
end
