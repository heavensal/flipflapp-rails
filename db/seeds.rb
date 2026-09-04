# frozen_string_literal: true

# Development-only demo dataset for manual UI testing.
# Run: bin/rails db:seed
#
# Cast: 20 users including id=3, 10 accepted friends, 10 upcoming events.

unless Rails.env.development?
  puts "⏭️  Seeds skipped outside development."
  return
end

require_relative "seeds/helpers"

include SeedHelpers

Faker::Config.locale = :fr

puts "🌱 Seeding FlipFlapp development data…"

me = User.find_by(id: 3)
abort "❌ User id=3 is required as the seed inbox target." if me.nil?

Event.where("title LIKE ? OR description LIKE ?", "[Seed]%", "%#{SEED_MARKER}%").find_each(&:destroy)
User.where("email LIKE ?", "%@#{SEED_DOMAIN}").find_each(&:destroy)
me.sent_friendships.destroy_all
me.received_friendships.destroy_all
me.notifications.delete_all

existing_others = User.where.not(id: me.id).order(:id).to_a
needed = [ TARGET_USER_COUNT - User.count, 0 ].max

seeded = needed.times.map do |index|
  create_user!(
    email: format("user%02d@#{SEED_DOMAIN}", index + 1),
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name
  )
end

others = existing_others + seeded
abort "❌ Need at least #{FRIEND_COUNT} other users besides id=3." if others.size < FRIEND_COUNT

puts "   #{User.count} users (#{seeded.size} created @#{SEED_DOMAIN} / #{SEED_PASSWORD})"
puts "   Inbox target: #{me.email} (id=#{me.id})"

friends = others.sample(FRIEND_COUNT)
strangers = others - friends

friends.each_with_index do |user, index|
  sender, receiver = index.even? ? [ me, user ] : [ user, me ]
  create_friendship!(sender, receiver, status: "accepted")
end

strangers.take(3).each { |user| create_friendship!(user, me, status: "pending") }
strangers.drop(3).take(2).each { |user| create_friendship!(me, user, status: "pending") }
strangers.drop(5).take(1).each { |user| create_friendship!(user, me, status: "declined") }

others.combination(2).to_a.sample(36).each do |sender, receiver|
  next if sender.friendship_with(receiver).present?

  create_friendship!(sender, receiver, status: (rand < 0.8) ? "accepted" : "pending")
end

puts "   #{Friendship.count} friendships (#{friends.size} accepted with id=#{me.id})"

pool = others
scenarios = [
  { private: false, me: :team_two, fill: :open, author: :friend },
  { private: false, me: :bench, fill: :full, author: :friend },
  { private: true, me: :invited, fill: :mid, author: :friend },
  { private: true, me: :team_two, fill: :mid, author: :friend },
  { private: false, me: :none, fill: :open, author: :stranger },
  { private: true, me: :bench, fill: :tight, author: :friend },
  { private: false, me: :team_two, fill: :full, author: :friend },
  { private: false, me: :none, fill: :mid, author: :friend },
  { private: true, me: :invited, fill: :open, author: :friend },
  { private: false, me: :team_one, fill: :tight, author: :friend }
]

seed_events = scenarios.first(EVENT_COUNT).map.with_index do |scenario, index|
  author_pool = scenario[:author] == :stranger && strangers.any? ? strangers : friends
  author = author_pool.sample || others.sample
  cap = { open: [ 8, 10 ], mid: [ 10, 12 ], tight: [ 10, 12 ], full: [ 8, 10 ] }.fetch(scenario[:fill]).sample

  create_event!(
    author: author,
    title: MATCH_TITLES[index % MATCH_TITLES.size],
    is_private: scenario[:private],
    number_of_participants: cap,
    start_time: future_kickoff
  ).tap do |event|
    rename_teams!(event)

    case scenario[:me]
    when :team_one, :team_two, :bench then join_team!(event, me, scenario[:me])
    end

    per_team = event.countable_slots_per_team
    targets = {
      open: [ 2, 2 ],
      mid: [ [ 3, per_team ].min, [ 3, per_team ].min ],
      tight: [ [ per_team - 1, 1 ].max, [ per_team - 1, 1 ].max ],
      full: [ per_team, event.countable_slots_for(team(event, :team_two)) ]
    }.fetch(scenario[:fill])

    fill_countable_team!(event, :team_one, pool, target_count: targets[0])
    fill_countable_team!(event, :team_two, pool, target_count: targets[1])
    fill_bench!(event, pool, count: rand(0..3))

    invite!(event, [ me ], sender: author) if scenario[:me] == :invited
    extra_invites = author.get_my_friends_but_not_participants(event).where.not(id: me.id).limit(2)
    invite!(event, extra_invites, sender: author)
  end
end

puts "   #{Event.count} events (#{seed_events.size} seeded upcoming matches)"
puts "   #{EventParticipant.count} participants, #{Invitation.count} invitations"
puts "   #{me.notifications.inbox.count} inbox notifications for user ##{me.id} (plus Sidekiq jobs)"

puts <<~SUMMARY

  ✅ Seed complete.

  You: #{me.email} (id=#{me.id})
  Friends: #{friends.size} accepted — pending in/out + declined also seeded
  Seed users: #{seeded.any? ? "user01@#{SEED_DOMAIN} … / #{SEED_PASSWORD}" : "none created (already #{User.count} users)"}

  Events:
#{seed_events.map { |event| "    • #{event.id} — #{event.title} (#{event.is_private? ? 'private' : 'public'}, #{event.start_time.to_fs(:short)})" }.join("\n")}

SUMMARY
