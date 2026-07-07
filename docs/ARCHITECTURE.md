# FlipFlapp Architecture

How the Rails app is organized. Business rules: [DOMAIN.md](DOMAIN.md). How to build features: [TESTING.md](TESTING.md).

## Stack

Rails 8 monolith · PostgreSQL (Neon) · Devise · ERB + Tailwind CSS 4 · Hotwire/Stimulus · RSpec · Kamal → `flipflapp.fr`

## Delivery phases

1. **Web UI** — primary surface to implement and verify MVP behavior
2. **JSON API** — same domain rules, after web flows are reliable (separate iOS/Android repos)

## MVC layers

| Layer | Path | Responsibility |
|-------|------|----------------|
| Models | `app/models/` | Domain behavior, validations, callbacks, `Notification` side effects |
| Controllers | `app/controllers/` | Auth, strong params, HTTP — thin; call model domain methods |
| Views | `app/views/` | ERB + Tailwind; components under `<feature>/components/` |
| JavaScript | `app/javascript/` | Stimulus when needed; ask before new controllers |
| Specs | `spec/models/` | Behavior tests (strict TDD) |

## MVP models

`User` · `Event` · `EventTeam` · `EventParticipant` · `Friendship` · `Notification`

Details: [DOMAIN.md](DOMAIN.md). Schema: `db/schema.rb`.

## HTTP surface

`config/routes.rb` — RESTful resources, Devise, nested `Events::InvitationsController`, notifications.

## Principles

- Rails MVC; boring code; match existing files in the same layer
- No service objects unless explicitly requested
- Files under 150 lines ([RAILS_STYLEGUIDE.md](RAILS_STYLEGUIDE.md))
- RuboCop Rails Omakase

## Sensitive areas

Devise · `Friendship` / `Event` visibility · participations · `Notification` · CarrierWave/Cloudinary · admin `role` · deploy config

Lock behavior with model specs before changing logic.

## Read next

| Need | Doc |
|------|-----|
| Rules | [DOMAIN.md](DOMAIN.md) |
| Style | [RAILS_STYLEGUIDE.md](RAILS_STYLEGUIDE.md) |
| Commands | [DEVELOPMENT.md](DEVELOPMENT.md) |
