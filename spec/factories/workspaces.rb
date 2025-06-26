FactoryBot.define do
  factory :workspace do
    name { Faker::Company.name }
    user
  end
end
