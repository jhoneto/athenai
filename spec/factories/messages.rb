FactoryBot.define do
  factory :message do
    session
    role { :user }
    content { "Hello" }
  end
end
