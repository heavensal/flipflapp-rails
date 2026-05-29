FactoryBot.define do
  factory :friendship do
    association :sender, factory: :user
    association :receiver, factory: :user
    status { "pending" }
  end
end
