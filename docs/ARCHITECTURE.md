# FlipFlapp Architecture

How the Rails app is organized. Business rules: [DOMAIN.md](DOMAIN.md). How to build features: [TESTING.md](TESTING.md).

## Stack

Rails 8 monolith · PostgreSQL (Neon) · Devise · ERB + Tailwind CSS 4 · Hotwire/Stimulus · RSpec · Kamal → `flipflapp.fr`

## Delivery phases

1. **Web UI** — primary surface to implement and verify MVP behavior
2. **JSON API** — `/api/v1`, same domain rules (separate iOS/Android repos). See [API.md](API.md)

## MVC layers

| Layer | Path | Responsibility |
|-------|------|----------------|
| Models | `app/models/` | Domain behavior, validations, callbacks, `Notification` side effects via per-model modules (`Event::Notifications`, etc.) + `Notification::Delivery` (enqueues jobs) |
| Jobs | `app/jobs/` | Solid Queue workers — e.g. `Notifications::DeliverOneJob` / `DeliverManyJob` (persist + Turbo Stream broadcast); local rules in [app/jobs/AGENTS.md](../app/jobs/AGENTS.md) |
| Controllers | `app/controllers/` | Auth, strong params, HTTP — thin; call model domain methods |
| API | `app/controllers/api/v1/` | JSON `/api/v1` — Bearer JWT; resource names mirror web; serializers in `app/serializers/` |
| Views | `app/views/` | ERB + Tailwind; components under `<feature>/components/` |
| JavaScript | `app/javascript/` | Stimulus when needed; ask before new controllers |
| Specs | `spec/models/` | Behavior tests (strict TDD) |

## MVP models

`User` · `Event` · `EventTeam` · `EventParticipant` · `Friendship` · `Invitation` · `Notification`

Details: [DOMAIN.md](DOMAIN.md). Schema: `db/schema.rb`.

## HTTP surface

`config/routes.rb` — RESTful web resources, Devise sessions, nested `Events::InvitationsController`, notifications, plus `namespace :api / :v1` for mobile.

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
| JSON API | [API.md](API.md) |
| Style | [RAILS_STYLEGUIDE.md](RAILS_STYLEGUIDE.md) |
| Commands | [DEVELOPMENT.md](DEVELOPMENT.md) |
