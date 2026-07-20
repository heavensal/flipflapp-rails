# frozen_string_literal: true

# Development-only demo dataset for manual UI testing.
# Run: bin/rails db:seed
#
# Uses existing users (does not create/destroy User records).
# Inbox target: User id 3

unless Rails.env.development?
  puts "⏭️  Seeds skipped outside development."
  return
end

SEED_DOMAIN = "flipflapp.seed"
SEED_PASSWORD = "password123"
DEMO_EMAIL = "demo@#{SEED_DOMAIN}"

module SeedHelpers
  module_function

  def team(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  def create_user!(email:, first_name:, last_name:)
    User.create!(
      email: email,
      password: SEED_PASSWORD,
      password_confirmation: SEED_PASSWORD,
      first_name: first_name,
      last_name: last_name,
      confirmed_at: Time.current
    )
  end

  def create_friendship!(sender, receiver, status: "accepted")
    Friendship.create!(sender: sender, receiver: receiver, status: status)
  rescue ActiveRecord::RecordInvalid => e
    puts "   ⚠️  Friendship skipped (#{sender.email} → #{receiver.email}): #{e.record.errors.full_messages.join(', ')}"
  end

  def create_event!(author:, title:, **attrs)
    defaults = {
      description: Faker::Lorem.paragraph(sentence_count: 2),
      location: "Complexe sportif #{Faker::Address.city}",
      start_time: Faker::Time.between(from: 2.days.from_now, to: 2.months.from_now),
      number_of_participants: 10,
      price: [ 0, 5, 10, 15 ].sample,
      is_private: false,
      latitude: Faker::Address.latitude,
      longitude: Faker::Address.longitude
    }
    Event.create!(defaults.merge(attrs).merge(user: author, title: title))
  end

  def available_users(event, users)
    users.reject { |user| event.in_this_event?(user) }
  end

  def join_team!(event, user, slot)
    return if event.in_this_event?(user)

    event_team = team(event, slot)
    return if event_team.countable? && event_team.full?
    return if event_team.countable? && event.countable_slots_full?

    event.event_participants.create!(user: user, event_team: event_team)
  end

  def fill_countable_team!(event, slot, users, target_count: nil)
    event_team = team(event, slot)
    target = target_count || event.countable_slots_per_team
    needed = target - event_team.event_participants.count
    return if needed <= 0

    available_users(event, users).shuffle.first(needed).each do |user|
      break if event_team.reload.full?

      event.event_participants.create!(user: user, event_team: event_team)
    end
  end

  def fill_bench!(event, users, count:)
    available_users(event, users).shuffle.first(count).each do |user|
      join_team!(event, user, :bench)
    end
  end

  def move_participant!(participant, slot)
    participant.update!(event_team: team(participant.event, slot))
  end

  def notification_payload_for(event, **extra)
    {
      title: event.title,
      start_time: event.start_time.iso8601
    }.merge(extra)
  end
end

include SeedHelpers

puts "🌱 Seeding FlipFlapp development data…"

# --- Users (commented: keep existing DB users) ---
# User.where("email LIKE ?", "%@#{SEED_DOMAIN}").destroy_all
# puts "   Cleared previous @#{SEED_DOMAIN} users."
#
# users = []
# users << create_user!(email: DEMO_EMAIL, first_name: "Demo", last_name: "FlipFlapp")
#
# 29.times do |index|
#   number = index + 1
#   users << create_user!(
#     email: format("user%02d@#{SEED_DOMAIN}", number),
#     first_name: Faker::Name.first_name,
#     last_name: Faker::Name.last_name
#   )
# end
#
# demo = users.first
# others = users.drop(1)
# puts "   #{users.size} users — login: #{DEMO_EMAIL} / #{SEED_PASSWORD}"

me = User.find(3)
others = User.where.not(id: me.id).order(:id).to_a
abort "❌ Need at least a few other users besides id=3." if others.size < 5

puts "   Inbox target: #{me.email} (id=#{me.id}) — #{others.size} other users available"

# --- Friendships ---
others.sample([ 10, others.size ].min).each { |user| create_friendship!(me, user, status: "accepted") }

others.reject { |user| me.friendship_with(user).present? }.sample([ 3, others.size ].min).each do |user|
  create_friendship!(user, me, status: "pending")
end

others.reject { |user| me.friendship_with(user).present? }.sample([ 2, others.size ].min).each do |user|
  create_friendship!(me, user, status: "pending")
end

others.combination(2).to_a.sample([ 12, others.combination(2).count ].min).each do |sender, receiver|
  next if Friendship.exists?(sender: sender, receiver: receiver)
  next if Friendship.exists?(sender: receiver, receiver: sender)

  create_friendship!(sender, receiver, status: %w[pending accepted].sample)
end

puts "   #{Friendship.count} friendships"

# --- Events (named scenarios for quick visual QA) ---
seed_events = []

event_team1_full = create_event!(
  author: me,
  title: "[Seed] Équipe 1 pleine (5/5)",
  description: "Team 1 complète : pas de bouton rejoindre. Team 2 et banc encore ouverts.",
  start_time: 3.days.from_now,
  price: 10,
  is_private: false
)
move_participant!(event_team1_full.event_participants.find_by!(user: me), :team_two)
fill_countable_team!(event_team1_full, :team_one, others, target_count: 5)
fill_countable_team!(event_team1_full, :team_two, others, target_count: 3)
fill_bench!(event_team1_full, others, count: 2)
team(event_team1_full, :team_one).update!(label: "Real Madrid")
seed_events << event_team1_full

event_globally_full = create_event!(
  author: others[0],
  title: "[Seed] Complet — banc seulement",
  description: "10/10 sur les équipes. Rejoindre une équipe impossible ; banc ouvert.",
  start_time: 5.days.from_now,
  price: 0,
  is_private: false
)
fill_countable_team!(event_globally_full, :team_one, others, target_count: 5)
fill_countable_team!(event_globally_full, :team_two, others, target_count: 5)
fill_bench!(event_globally_full, [ me ] + others, count: 3)
seed_events << event_globally_full

event_sparse = create_event!(
  author: me,
  title: "[Seed] Places libres",
  description: "Peu de joueurs : tous les boutons rejoindre visibles.",
  start_time: 1.week.from_now,
  is_private: false
)
fill_countable_team!(event_sparse, :team_two, others, target_count: 2)
seed_events << event_sparse

event_private_invited = create_event!(
  author: others[1],
  title: "[Seed] Privé — tu es invité",
  description: "Événement privé visible via invitation.",
  start_time: 10.days.from_now,
  is_private: true
)
seed_events << event_private_invited

event_private_joined = create_event!(
  author: others[2],
  title: "[Seed] Privé — tu participes",
  start_time: 12.days.from_now,
  is_private: true
)
join_team!(event_private_joined, me, :team_two)
fill_countable_team!(event_private_joined, :team_one, others, target_count: 3)
seed_events << event_private_joined

event_derby = create_event!(
  author: others[3],
  title: "[Seed] Derby Bleus vs Rouges",
  start_time: 2.weeks.from_now,
  is_private: false
)
team(event_derby, :team_one).update!(label: "Les Bleus")
team(event_derby, :team_two).update!(label: "Les Rouges")
fill_countable_team!(event_derby, :team_one, others, target_count: 4)
fill_countable_team!(event_derby, :team_two, others, target_count: 4)
join_team!(event_derby, me, :bench)
seed_events << event_derby

event_bench_demo = create_event!(
  author: others[4],
  title: "[Seed] Demo sur le banc",
  start_time: 4.days.from_now,
  is_private: false
)
fill_countable_team!(event_bench_demo, :team_one, others, target_count: 4)
fill_countable_team!(event_bench_demo, :team_two, others, target_count: 4)
join_team!(event_bench_demo, me, :bench)
seed_events << event_bench_demo

8.times do |index|
  author = others.sample
  seed_events << create_event!(
    author: author,
    title: "[Seed] #{Faker::Sport.sport} — #{Faker::Address.city} ##{index + 1}",
    is_private: index.even?,
    number_of_participants: [ 8, 10, 12 ].sample,
    start_time: Faker::Time.between(from: 3.days.from_now, to: 6.weeks.from_now)
  ).tap do |event|
    next if index.even? && !event.is_private?

    fill_countable_team!(event, :team_one, others, target_count: rand(2..4))
    fill_countable_team!(event, :team_two, others, target_count: rand(1..3))
    fill_bench!(event, others, count: rand(0..2))
  end
end

puts "   #{Event.count} events (#{seed_events.size} curated scenarios)"

# --- Notifications for user id 3 inbox ---
me.notifications.inbox.delete_all

inbox_events = seed_events.select(&:persisted?)
players = others.map(&:first_name)

Invitation.find_or_create_by!(event: event_private_invited, user: me)
Notification.create!(
  user: me,
  notifiable: event_private_invited,
  kind: :invited,
  read: false,
  payload: notification_payload_for(event_private_invited, sender: others[1].first_name)
)

25.times do |index|
  event = inbox_events.sample
  actor = others.sample

  Notification.create!(
    user: me,
    notifiable: event,
    kind: :joined,
    read: index.even?,
    payload: notification_payload_for(event, player: players.sample),
    created_at: (25 - index).hours.ago
  )
end

20.times do |index|
  event = inbox_events.sample

  Notification.create!(
    user: me,
    notifiable: event,
    kind: :left,
    read: index % 3 == 0,
    payload: notification_payload_for(event, player: players.sample),
    created_at: (20 - index).hours.ago
  )
end

15.times do |index|
  event = inbox_events.sample
  actor = others.sample
  field, old_value, new_value = [
    [ "title", "Ancien titre", event.title ],
    [ "price", "10.00", format("%.2f", event.price.to_f) ],
    [ "start_time", 1.week.from_now.iso8601, event.start_time.iso8601 ],
    [ "number_of_participants", "8", event.number_of_participants.to_s ]
  ].sample

  Notification.create!(
    user: me,
    notifiable: event,
    kind: :updated,
    read: false,
    payload: notification_payload_for(
      event,
      actor: actor.first_name,
      field: field,
      old_value: old_value,
      new_value: new_value,
      title: field == "title" ? old_value : event.title
    ),
    created_at: (15 - index).hours.ago
  )
end

12.times do |index|
  event = inbox_events.sample
  sender = others.sample

  Notification.create!(
    user: me,
    notifiable: event,
    kind: :invited,
    read: index > 8,
    payload: notification_payload_for(event, sender: sender.first_name),
    created_at: (12 - index).hours.ago
  )
end

8.times do |index|
  author = others.sample

  Notification.create!(
    user: me,
    notifiable: nil,
    kind: :canceled,
    read: index.odd?,
    payload: {
      title: "[Seed] Match annulé ##{index + 1}",
      start_time: (index + 1).days.ago.iso8601,
      author: author.first_name
    },
    created_at: (8 - index).hours.ago
  )
end

6.times do |index|
  event = inbox_events.sample

  Notification.create!(
    user: me,
    notifiable: event,
    kind: :reminder,
    read: false,
    payload: notification_payload_for(event),
    created_at: (6 - index).hours.ago
  )
end

puts "   #{me.notifications.inbox.count} inbox notifications for user ##{me.id}"
puts "   #{Notification.count} notifications total"

puts <<~SUMMARY

  ✅ Seed complete (users untouched).

  Inbox user: #{me.email} (id=#{me.id})
  Unread:     #{me.notifications.inbox.unread.count}

  Key events to open:
    • #{event_team1_full.id} — #{event_team1_full.title}
    • #{event_globally_full.id} — #{event_globally_full.title}
    • #{event_sparse.id} — #{event_sparse.title}
    • #{event_private_invited.id} — #{event_private_invited.title} (invited, not joined)
    • #{event_bench_demo.id} — #{event_bench_demo.title} (demo on bench)

SUMMARY
