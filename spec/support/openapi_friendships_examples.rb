# frozen_string_literal: true

module OpenapiFriendshipsExamples
  CREATED_AT = "2026-08-02T10:00:00.000Z"
  UPDATED_AT = "2026-08-02T10:05:00.000Z"

  AUTH_ERROR_401 = OpenapiEventsExamples::AUTH_ERROR_401
  ERROR_404 = OpenapiEventsExamples::ERROR_404
  ERROR_403 = OpenapiEventsExamples::ERROR_403

  SENDER = {
    id: 1,
    first_name: "Ada",
    last_name: "Lovelace",
    username: "ada#0001",
    avatar_url: "https://cdn.flipflapp.test/avatars/ada-0001/medium.jpg"
  }.freeze

  RECEIVER = {
    id: 2,
    first_name: "Grace",
    last_name: "Hopper",
    username: "grace#0002",
    avatar_url: nil
  }.freeze

  SEARCH_HIT = {
    id: 3,
    first_name: "Zinedine",
    last_name: "Zidane",
    username: "zizou#0003",
    avatar_url: nil
  }.freeze

  PENDING = {
    id: 10,
    sender_id: 1,
    receiver_id: 2,
    status: "pending",
    created_at: CREATED_AT,
    updated_at: CREATED_AT,
    sender: SENDER,
    receiver: RECEIVER
  }.freeze

  ACCEPTED = PENDING.merge(
    status: "accepted",
    updated_at: UPDATED_AT
  ).freeze

  DECLINED = PENDING.merge(
    status: "declined",
    updated_at: UPDATED_AT
  ).freeze

  BUCKETS = {
    accepted: [ ACCEPTED ],
    sent: [ PENDING ],
    received: [],
    declined: []
  }.freeze

  EMPTY_BUCKETS = {
    accepted: [],
    sent: [],
    received: [],
    declined: []
  }.freeze

  ERROR_422_SELF = {
    error: {
      message: "Validation failed",
      details: {
        receiver_id: [ "Vous ne pouvez pas vous envoyer une demande d'amitié à vous-même." ]
      }
    }
  }.freeze

  ERROR_422_DUPLICATE = {
    error: {
      message: "Validation failed",
      details: {
        sender_id: [ "Demande d'amitié déjà envoyée." ]
      }
    }
  }.freeze

  ERROR_422_REVERSE = {
    error: {
      message: "Validation failed",
      details: {
        base: [ "Une demande d'amitié existe déjà entre ces utilisateurs." ]
      }
    }
  }.freeze
end
