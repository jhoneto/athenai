FactoryBot.define do
  factory :function do
    name { Faker::Name.unique.name }
    code { Faker::Lorem.paragraph }
    association :workspace
  end
end
