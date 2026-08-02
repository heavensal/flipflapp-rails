# frozen_string_literal: true

module OpenapiEventsExamples
  EVENT_ID = 42
  EVENT_TIME = "2026-08-13T18:30:00.000Z"
  CREATED_AT = "2026-08-02T10:00:00.000Z"

  AUTH_ERROR_401 = {
    error: { message: "You need to sign in or sign up before continuing." }
  }.freeze

  ERROR_404 = { error: { message: "Not found" } }.freeze
  ERROR_403 = { error: { message: "Forbidden" } }.freeze
  # Default locale is fr; message text follows I18n at request time.
  ERROR_403_RENAME_NOT_PARTICIPANT = {
    error: { message: "Seuls les participants peuvent renommer une équipe." }
  }.freeze
  ERROR_403_RENAME_BENCH = {
    error: { message: "Le banc ne peut pas être renommé." }
  }.freeze
  ERROR_422_VALIDATION = {
    error: {
      message: "Validation failed",
      details: { title: [ "can't be blank" ] }
    }
  }.freeze
  ERROR_422_TEAM_LABEL = {
    error: {
      message: "Validation failed",
      details: { label: [ "Label is invalid" ] }
    }
  }.freeze
  ERROR_422_TEAM_LABEL_TAKEN = {
    error: {
      message: "Validation failed",
      details: { label: [ "Label has already been taken" ] }
    }
  }.freeze
  ERROR_422_TEAM_LABEL_TOO_LONG = {
    error: {
      message: "Validation failed",
      details: { label: [ "Label is too long (maximum is 24 characters)" ] }
    }
  }.freeze
  ERROR_422_NO_USERS_TO_INVITE = { error: { message: "No users to invite" } }.freeze
  ERROR_422_TEAM_FULL = {
    error: {
      message: "Validation failed",
      details: { event_team: [ "Event team this team is full" ] }
    }
  }.freeze

  PUBLIC_USER = {
    id: 7,
    first_name: "Camille",
    last_name: "Dupont",
    username: "camilled#0007",
    avatar_url: "https://cdn.flipflapp.test/avatars/camilled-0007/medium.jpg"
  }.freeze

  GUEST_USER = {
    id: 12,
    first_name: "Lucas",
    last_name: "Bernard",
    username: "lucasb#0012",
    avatar_url: nil
  }.freeze

  EVENT_AUTHOR_VIEWER = {
    participant: true, can_invite: true, author: true, invited: false
  }.freeze
  EVENT_PARTICIPANT_VIEWER = {
    participant: true, can_invite: true, author: false, invited: false
  }.freeze
  EVENT_INVITED_VIEWER = {
    participant: false, can_invite: false, author: false, invited: true
  }.freeze
  EVENT_STRANGER_VIEWER = {
    participant: false, can_invite: false, author: false, invited: false
  }.freeze

  VIEWER_CONTEXTS = {
    author: EVENT_AUTHOR_VIEWER,
    participant: EVENT_PARTICIPANT_VIEWER,
    invited: EVENT_INVITED_VIEWER,
    stranger: EVENT_STRANGER_VIEWER
  }.freeze

  EVENT_BASE = {
    id: EVENT_ID,
    title: "Wednesday 5-a-side — Bois de Boulogne",
    description: "Casual kickabout on the Paris 16 synthetic pitch. Bring dark and light shirts.",
    location: "Bois de Boulogne, Paris 16e",
    start_time: EVENT_TIME,
    number_of_participants: 10,
    price: "8.0",
    is_private: false,
    latitude: "48.862725",
    longitude: "2.249899",
    user_id: PUBLIC_USER[:id],
    created_at: CREATED_AT,
    updated_at: CREATED_AT,
    participants_count: 3,
    spots_remaining: 7,
    fill_level: "open",
    user: PUBLIC_USER
  }.freeze

  def self.event_example(viewer_context:)
    EVENT_BASE.merge(current_user: VIEWER_CONTEXTS.fetch(viewer_context))
  end

  EVENT_TEAM_ONE = {
    id: 10, event_id: EVENT_ID, slot: "team_one", label: "Bleus",
    created_at: CREATED_AT, updated_at: CREATED_AT, countable: true
  }.freeze
  EVENT_TEAM_TWO = {
    id: 11, event_id: EVENT_ID, slot: "team_two", label: "Rouges",
    created_at: CREATED_AT, updated_at: CREATED_AT, countable: true
  }.freeze
  EVENT_TEAM_BENCH = {
    id: 12, event_id: EVENT_ID, slot: "bench", label: "On the bench",
    created_at: CREATED_AT, updated_at: CREATED_AT, countable: false
  }.freeze

  EVENT_PARTICIPANT = {
    id: 20, event_id: EVENT_ID, event_team_id: EVENT_TEAM_ONE[:id],
    user_id: GUEST_USER[:id], created_at: CREATED_AT, updated_at: CREATED_AT,
    user: GUEST_USER
  }.freeze

  INVITATION = {
    id: 30, event_id: EVENT_ID, user_id: GUEST_USER[:id],
    created_at: CREATED_AT, updated_at: CREATED_AT, user: GUEST_USER
  }.freeze

  CREATE_EVENT_REQUEST = {
    event: {
      title: "Wednesday 5-a-side — Bois de Boulogne",
      description: "Casual kickabout on the Paris 16 synthetic pitch. Bring dark and light shirts.",
      location: "Bois de Boulogne, Paris 16e",
      start_time: EVENT_TIME,
      number_of_participants: 10,
      price: 8.0,
      is_private: false,
      latitude: 48.862725,
      longitude: 2.249899
    }
  }.freeze

  UPDATE_EVENT_REQUEST = {
    event: { title: "Wednesday 5-a-side — Parc des Princes warm-up", price: 10.0 }
  }.freeze

  JOIN_REQUEST = { event_participant: { event_team_id: EVENT_TEAM_ONE[:id] } }.freeze
  RENAME_TEAM_REQUEST = { event_team: { label: "France 98" } }.freeze
  INVITE_REQUEST = { user_ids: [ GUEST_USER[:id] ] }.freeze
end
