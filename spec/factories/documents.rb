FactoryBot.define do
  factory :document do
    knowledge_base
    sequence(:filename) { |n| "document-#{n}.txt" }
    status { :pending }
  end
end
