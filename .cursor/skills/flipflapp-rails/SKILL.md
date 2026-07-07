---
name: flipflapp-rails
description: >-
  FlipFlapp feature workflow: DOMAIN → TESTING → RAILS_STYLEGUIDE.
  Use for models, controllers, views, specs, or migrations.
---

# FlipFlapp Rails skill

## Before a feature

1. [docs/PROJECT.md](../../docs/PROJECT.md) — in scope?
2. [docs/DOMAIN.md](../../docs/DOMAIN.md) — business rules
3. [config/routes.rb](../../config/routes.rb) — HTTP surface
4. Nearby code in the same layer — copy conventions

## Feature workflow

Follow [docs/TESTING.md](../../docs/TESTING.md):

1. User describes behavior
2. Agent flags ambiguities — user answers
3. Update DOMAIN if needed
4. Propose migrations — user validates before any `db/migrate/` file
5. Failing `spec/models/` specs
6. Implement (model first, then controllers / views)

## Style

- [docs/RAILS_STYLEGUIDE.md](../../docs/RAILS_STYLEGUIDE.md) — Rails, RuboCop, &lt;150 lines
- [docs/FRONTEND.md](../../docs/FRONTEND.md) — ERB, Tailwind, components, Stimulus

## Commands (only when user asks)

See [docs/DEVELOPMENT.md](../../docs/DEVELOPMENT.md): `bin/dev`, `rspec`, `bin/rubocop`.

## Do not

- Migrations, `rspec`, commit, or push unless explicitly requested
- Service objects unless explicitly requested
- New Stimulus controller without asking
