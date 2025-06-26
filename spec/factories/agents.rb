FactoryBot.define do
  factory :agent do
    name { Faker::Superhero.name }
    prompt { Faker::Lorem.paragraph(sentence_count: 3) }
    association :workspace
    association :llm
  end
end
