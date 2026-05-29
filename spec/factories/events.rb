FactoryBot.define do
  factory :event do
    association :user
    title { "Match amical" }
    description { "Description de l'événement" }
    location { "Paris" }
    start_time { 2.days.from_now }
    number_of_participants { 10 }
    price { 10.0 }
    is_private { true }
  end
end
