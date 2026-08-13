FactoryBot.define do
  factory :session do
    account
    agent { create(:agent, :published, account: account) }
    user
    status { :open }
  end
end
