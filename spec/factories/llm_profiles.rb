FactoryBot.define do
  factory :llm_profile, class: "Llm::Profile" do
    sequence(:name) { |n| "Profile #{n}" }
    key { :fast }
    credit_multiplier { 1.0 }
    active { true }
    llm_model
  end
end
