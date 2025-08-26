# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Créer 20 utilisateurs avec des noms de personnages de manga

manga_characters = [
  { first: "Monkey D.", last: "Luffy", manga: "One Piece" },
  { first: "Roronoa", last: "Zoro", manga: "One Piece" },
  { first: "Nami", last: "Navigator", manga: "One Piece" },
  { first: "Usopp", last: "Sniper", manga: "One Piece" },
  { first: "Vinsmoke", last: "Sanji", manga: "One Piece" },
  { first: "Tony Tony", last: "Chopper", manga: "One Piece" },
  { first: "Nico", last: "Robin", manga: "One Piece" },
  { first: "Uzumaki", last: "Naruto", manga: "Naruto" },
  { first: "Uchiha", last: "Sasuke", manga: "Naruto" },
  { first: "Haruno", last: "Sakura", manga: "Naruto" },
  { first: "Hatake", last: "Kakashi", manga: "Naruto" },
  { first: "Hyuga", last: "Hinata", manga: "Naruto" },
  { first: "Kurosaki", last: "Ichigo", manga: "Bleach" },
  { first: "Kuchiki", last: "Rukia", manga: "Bleach" },
  { first: "Dragneel", last: "Natsu", manga: "Fairy Tail" },
  { first: "Heartfilia", last: "Lucy", manga: "Fairy Tail" },
  { first: "Kamado", last: "Tanjiro", manga: "Demon Slayer" },
  { first: "Kamado", last: "Nezuko", manga: "Demon Slayer" },
  { first: "Son", last: "Goku", manga: "Dragon Ball" },
  { first: "Vegeta", last: "Prince", manga: "Dragon Ball" },
  { first: "Midoriya", last: "Izuku", manga: "My Hero Academia" },
  { first: "Bakugo", last: "Katsuki", manga: "My Hero Academia" },
  { first: "Todoroki", last: "Shoto", manga: "My Hero Academia" },
  { first: "Edward", last: "Elric", manga: "Fullmetal Alchemist" },
  { first: "Alphonse", last: "Elric", manga: "Fullmetal Alchemist" }
]

20.times do |i|
  character = manga_characters[i] || manga_characters.sample

  seed_user = User.create_with(
    password: 'password',
    password_confirmation: 'password',
    first_name: character[:first],
    last_name: character[:last]
  ).find_or_create_by!(email: "#{character[:first].downcase.gsub(/[^a-z]/, '')}.#{character[:last].downcase.gsub(/[^a-z]/, '')}#{i}@manga-sports.com")

  seed_user.confirm unless seed_user.confirmed?
  puts "User created: #{seed_user.first_name} #{seed_user.last_name} - (#{seed_user.email})"
end

# Créer 20 events
#   create_table "events", force: :cascade do |t|
  #   t.string "title", null: false
  #   t.text "description"
  #   t.string "location", null: false
  #   t.datetime "start_time", null: false
  #   t.integer "number_of_participants", default: 10, null: false
  #   t.decimal "price", precision: 10, scale: 2, default: "10.0", null: false
  #   t.boolean "is_private", default: true, null: false
  #   t.bigint "user_id", null: false
  #   t.datetime "created_at", null: false
  #   t.datetime "updated_at", null: false
  #   t.index ["user_id"], name: "index_events_on_user_id"
  # end
20.times do |i|
  seed_event = Event.create!(
    # Titres d'événements sportifs plus réalistes
    title: [
      "#{Faker::Team.sport} - Match #{Faker::Team.name} vs #{Faker::Team.name}",
      "Tournoi de #{Faker::Team.sport} - #{Faker::Address.city}",
      "#{Faker::Team.sport} Amateur - Saison #{Date.current.year}",
      "Match Amical #{Faker::Team.sport}",
      "Championnat Local de #{Faker::Team.sport}"
    ].sample,

    # Descriptions plus variées
    description: [
      Faker::JapaneseMedia::OnePiece.quote,
      "Venez participer à cet événement sportif ! #{Faker::Lorem.sentence}",
      "#{Faker::Movies::StarWars.quote} - Un événement à ne pas manquer !",
      "#{Faker::TvShows::Friends.quote}",
      Faker::Lorem.paragraph(sentence_count: 3)
    ].sample,

    # Lieux plus variés (gymnases, stades, etc.)
    location: [
      "Gymnase #{Faker::Address.city}",
      "Stade #{Faker::Name.last_name}",
      "Centre Sportif #{Faker::Address.street_name}",
      "Complexe Sportif de #{Faker::Address.city}",
      "#{Faker::Address.street_address}, #{Faker::Address.city}"
    ].sample,

    # Horaires plus variés
    start_time: Faker::Time.between(
      from: 1.week.from_now,
      to: 2.months.from_now,
      format: :default
    ),

    # Nombre de participants varié
    number_of_participants: [8, 10, 12, 16, 20, 24].sample,

    # Prix variés et réalistes
    price: [0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0].sample,

    is_private: [true, false, false].sample, # Plus d'événements publics
    user: User.all.sample # ✅ Utilise un utilisateur aléatoire parmi tous les utilisateurs existants
  )
  puts "Event created: #{seed_event.title} - (#{seed_event.id}) - by #{seed_event.user.first_name}"

  # Pour chaque event, créer entre 1 et 10 participants
  available_users = User.all.to_a
  participants_count = rand(1..10)

  participants_count.times do
    # Éviter les doublons d'utilisateurs dans le même événement
    available_user = available_users.sample
    next if seed_event.event_participants.exists?(user: available_user)

    seed_event.event_participants.create!(
      user: available_user,
      event_team: seed_event.event_teams.sample
    )
    puts "Participant added: #{available_user.first_name} - participant_id: #{available_user.id} to event #{seed_event.title} - event_id: #{seed_event.id}"
  end

end
