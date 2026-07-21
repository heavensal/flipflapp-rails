---
name: flipflapp-rails
description: >-
  FlipFlapp feature workflow: DOMAIN → TESTING → RAILS_STYLEGUIDE → API.
  Use for models, controllers, views, specs, API, or migrations.
---

# FlipFlapp Rails skill

## Before a feature

1. [docs/PROJECT.md](../../docs/PROJECT.md) — in scope?
2. [docs/DOMAIN.md](../../docs/DOMAIN.md) — business rules
3. [config/routes.rb](../../config/routes.rb) — HTTP surface (web + `/api/v1`)
4. Nearby code in the same layer — copy conventions
5. If mobile clients are affected — [docs/API.md](../../docs/API.md)

## Feature workflow

Follow [docs/TESTING.md](../../docs/TESTING.md):

1. User describes behavior
2. Agent flags ambiguities — user answers
3. Update DOMAIN if needed
4. Propose migrations — user validates before any `db/migrate/` file
5. Failing `spec/models/` specs
6. Implement (model first, then controllers / views)
7. If the HTTP contract for mobile changes — update `/api/v1`, `spec/requests/api/v1/`, serializers, and OpenAPI (rswag) in the same change

## Style

- [docs/RAILS_STYLEGUIDE.md](../../docs/RAILS_STYLEGUIDE.md) — Rails, RuboCop, &lt;150 lines
- [docs/FRONTEND.md](../../docs/FRONTEND.md) — ERB, Tailwind, components, Stimulus
- API resource names = web names (`event_participants`, not aliases)

## Commands (only when user asks)

See [docs/DEVELOPMENT.md](../../docs/DEVELOPMENT.md): `bin/dev`, `rspec`, `bin/rubocop`, `rake rswag:specs:swaggerize`.

## Do not

- Migrations, `rspec`, commit, or push unless explicitly requested
- Service objects unless explicitly requested
- New Stimulus controller without asking
