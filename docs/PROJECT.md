# FlipFlapp

> Web app for organizing football `Event` records with friends — invite `User` records, share match details, and know who is coming before kickoff.

## Who it's for

- Every `User` can create `Event` records and join via `EventParticipant`.
- Typical capacity: **5v5 futsal** (~10 on `team_one` + `team_two`) or **11v11** outdoor football.
- **MVP sport**: football only.

## This repository

- Rails 8 app: **web UI** + **JSON API** (`/api/v1` — see [API.md](API.md)).
- Web is the fast surface to **design, verify, and test** backend behavior; mobile clients consume the same domain via the API.
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
| `Invitation` | Pending invite to an `Event` (unique per user); removed on join |
| `Notification` | In-app alerts (future iOS/Android push) |

## MVP scope (in)

- Full behavior for `User`, `Event`, `EventTeam`, `EventParticipant`, `Friendship`, `Notification`.
- `User` with `role: admin` — CRUD all MVP data (see [DOMAIN.md](DOMAIN.md)).
- JSON API `/api/v1` for mobile clients ([API.md](API.md)).

## MVP quality target

"MVP" limits product breadth, not engineering quality. A flow is complete only when all applicable gates below pass:

- **Documented behavior** — the rule is explicit in [DOMAIN.md](DOMAIN.md), including access, edge cases, and side effects.
- **End-to-end web flow** — an authenticated user can complete the intended action through the Rails UI without console or database intervention.
- **Data integrity** — model validations, associations, transactions where needed, and database constraints protect the rule.
- **Authorization** — controllers explicitly authenticate and authorize every protected read or write; admin override remains intentional.
- **TDD contract** — model behavior is covered in `spec/models/`; material HTTP contracts are covered in `spec/requests/`.
- **Consistent UI** — semantic ERB, existing Tailwind language, responsive layout, and I18n keys for user-facing copy.
- **Operational fit** — background work uses the installed Rails stack, errors fail safely, and no secret or production-only assumption leaks into code.
- **MVP discipline** — the solution adds no payments, chat, rankings, OAuth, mobile app code, or generalized abstraction. Keep `/api/v1` aligned with documented domain rules (no speculative endpoints).

The target is a coherent, secure, maintainable football organizer—not a prototype with incomplete rules and not a platform built ahead of demand.

## Product decision order

When requirements compete, decide in this order:

1. Rules and explicit user decisions in [DOMAIN.md](DOMAIN.md).
2. Security, authorization, and data integrity.
3. Complete web MVP flow for the normal player journey.
4. Simple conventional Rails implementation.
5. UI polish using the existing Tailwind language.
6. Keep `/api/v1` and OpenAPI in sync when a feature changes the mobile HTTP contract ([API.md](API.md)).

## Out of scope

- Payments, chat, rankings, Google OAuth.
- Swift / Kotlin mobile app code.
- Anything outside the MVP models above.

## Where to read next

| Question | Doc |
|----------|-----|
| Business rules | [DOMAIN.md](DOMAIN.md) |
| JSON API / iOS | [API.md](API.md) |
| Code style | [RAILS_STYLEGUIDE.md](RAILS_STYLEGUIDE.md) |
| Feature development (TDD) | [TESTING.md](TESTING.md) |
| Local setup and commands | [DEVELOPMENT.md](DEVELOPMENT.md) |
| Code layout | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Translations | [I18N.md](I18N.md) |
| Agent policy | [AGENTS.md](../AGENTS.md) |

## Language

- Technical text: **English**.
- User-facing copy: **French first**; structure all strings with **I18n keys** even when only `fr` locale files exist today.
