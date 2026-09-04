# frozen_string_literal: true

SEED_DOMAIN = "flipflapp.seed"
SEED_PASSWORD = "password123"
SEED_MARKER = "[dev-seed]"
TARGET_USER_COUNT = 20
FRIEND_COUNT = 10
EVENT_COUNT = 10

TEAM_NAMES = [
  "Les Tigres", "FC Croissant", "Team Pastis", "Les Bleus",
  "Real Madrid", "Barca Amateur", "Olympique Nul", "Les Martiens",
  "Super Sub", "PSG du Dimanche", "Les Nuls", "Force Tranquille",
  "Les Marseillais", "FC Banlieue", "Team Raclette", "Les Invincibles",
  "Chaussettes Noires", "Les Localos", "FC Fromage", "Les Costauds"
].freeze

MATCH_TITLES = [
  "Derby du dimanche", "Five sous la pluie", "Match des voisins",
  "Tournoi express", "Foot entre potes", "Challenge pizza",
  "Revanche 2026", "Amical du bois", "Night game Vincennes",
  "Match a huit", "Bouclier de la soif", "Classico amateur"
].freeze

PITCHES = [
  { location: "Stade Pershing, Paris", latitude: 48.8286, longitude: 2.4503 },
  { location: "Terrain Suzanne Lenglen, Paris", latitude: 48.8302, longitude: 2.2731 },
  { location: "Stade de la Muette, Paris", latitude: 48.8619, longitude: 2.2708 },
  { location: "Complexe sportif Alain Mimoun", latitude: 48.8364, longitude: 2.4107 },
  { location: "Stade Leon Biancotto, Paris", latitude: 48.8947, longitude: 2.3214 },
  { location: "Pelouse de Reuilly, Paris", latitude: 48.8401, longitude: 2.3992 }
].freeze

module SeedHelpers
  module_function

  def team(event, slot)
    event.event_teams.find_by!(slot: slot)
  end

  def create_user!(email:, first_name:, last_name:)
    User.new(
      email: email,
      password: SEED_PASSWORD,
      password_confirmation: SEED_PASSWORD,
      first_name: first_name,
      last_name: last_name
    ).tap do |user|
      user.skip_confirmation!
      user.skip_confirmation_notification!
      user.save!
    end
  end

  def create_friendship!(sender, receiver, status: "accepted")
    Friendship.create!(sender: sender, receiver: receiver, status: status)
  rescue ActiveRecord::RecordInvalid => e
    puts "   ⚠️  Friendship skipped (#{sender.email} → #{receiver.email}): #{e.record.errors.full_messages.join(', ')}"
  end

  def future_kickoff
    date = rand(2..50).days.from_now.to_date
    Time.zone.local(date.year, date.month, date.day, [ 18, 19, 20, 21 ].sample, [ 0, 15, 30 ].sample)
  end

  def create_event!(author:, title:, **attrs)
    pitch = PITCHES.sample
    defaults = {
      description: "#{Faker::Lorem.paragraph(sentence_count: 2)} #{SEED_MARKER}",
      location: pitch[:location],
      start_time: future_kickoff,
      number_of_participants: [ 8, 10, 12 ].sample,
      price: [ 0, 5, 8, 10, 15 ].sample,
      is_private: false,
      latitude: pitch[:latitude],
      longitude: pitch[:longitude]
    }
    Event.create!(defaults.merge(attrs).merge(user: author, title: title))
  end

  def available_users(event, users)
    users.reject { |user| event.in_this_event?(user) }
  end

  def joinable_users(event, users)
    available_users(event, users).select { |user| event.joinable_by?(user) }
  end

  def join_team!(event, user, slot)
    return if user.blank? || event.in_this_event?(user)
    return unless event.joinable_by?(user)

    event_team = team(event, slot)
    return if event_team.countable? && (event_team.full? || event.countable_slots_full?)

    event.event_participants.create!(user: user, event_team: event_team)
  end

  def fill_countable_team!(event, slot, users, target_count:)
    event_team = team(event, slot)
    needed = target_count - event_team.event_participants.count
    return if needed <= 0

    joinable_users(event, users).shuffle.first(needed).each do |user|
      break if event_team.reload.full? || event.reload.countable_slots_full?

      event.event_participants.create!(user: user, event_team: event_team)
    end
  end

  def fill_bench!(event, users, count:)
    joinable_users(event, users).shuffle.first(count).each { |user| join_team!(event, user, :bench) }
  end

  def rename_teams!(event)
    names = TEAM_NAMES.sample(2)
    team(event, :team_one).update!(label: names.first)
    team(event, :team_two).update!(label: names.last)
  end

  def invite!(event, users, sender:)
    Array(users).compact.uniq.each do |user|
      next if user == sender || event.in_this_event?(user) || event.invited?(user)
      next unless sender.is_friend_with?(user)

      event.invite!(users: [ user ], sender: sender)
    end
  end
end
