# FlipFlapp

> Web app for organizing football `Event` records with friends — invite `User` records, share match details, and know who is coming before kickoff.

## Who it's for

- Every `User` can create `Event` records and join via `EventParticipant`.
- Typical capacity: **5v5 futsal** (~10 on `team_one` + `team_two`) or **11v11** outdoor football.
- **MVP sport**: football only.

## This repository

- Rails 8 app: **web UI** + **JSON API** (API comes after the web flows work end-to-end).
- Web is the fast surface to **design, verify, and test** backend behavior before iOS/Android clients ship.
- Production: **flipflapp.fr**
- Mobile apps live in **separate Swift and Kotlin repos** — not here.

## Models (MVP)

| Model | Role |
|-------|------|
| `User` | Account; organizer and participant |
| `Event` | Football match (`is_private`, capacity, schedule) |
| `EventTeam` | `team_one`, `team_two`, `bench` per `Event` |
| `EventParticipant` | `User` on an `Event` + `EventTeam` |
| `Friendship` | Social graph; private `Event` visibility and invites |
| `Notification` | In-app alerts (future iOS/Android push) |

## MVP scope (in)

- Full behavior for `User`, `Event`, `EventTeam`, `EventParticipant`, `Friendship`, `Notification`.
- `User` with `role: admin` — CRUD all MVP data (see [DOMAIN.md](DOMAIN.md)).
- JSON API after web flows are reliable.

## Out of scope

- Payments, chat, rankings, Google OAuth.
- Swift / Kotlin mobile app code.
- Anything outside the MVP models above.

## Where to read next

| Question | Doc |
|----------|-----|
| Business rules | [DOMAIN.md](DOMAIN.md) |
| Code style | [RAILS_STYLEGUIDE.md](RAILS_STYLEGUIDE.md) |
| Feature development (TDD) | [TESTING.md](TESTING.md) |
| Local setup and commands | [DEVELOPMENT.md](DEVELOPMENT.md) |
| Code layout | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Translations | [I18N.md](I18N.md) |
| Agent policy | [AGENTS.md](../AGENTS.md) |

## Language

- Technical text: **English**.
- User-facing copy: **French first**; structure all strings with **I18n keys** even when only `fr` locale files exist today.
