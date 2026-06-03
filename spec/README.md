# Tests

See `spec/AGENTS.md` and `docs/TESTING.md` for the full testing policy.

FlipFlapp uses strict TDD with RSpec and Factory Bot.

## Scope

- Model specs only by default: `spec/models/`.
- Cover validations, uniqueness, callbacks, CRUD data effects, notifications, friendship rules, event rules, and team rules.
- Do not add request, view, helper, system, or display-only specs unless explicitly requested.
- Do not use YAML fixtures.
- Do not leave pending examples.

## Database

RSpec uses **`TEST_NEON_DB`** from `.env` only (not `DEVELOPMENT_NEON_DB` or `PRODUCTION_NEON_DB`).

```bash
# .env must include:
# TEST_NEON_DB=postgresql://...
bin/rails db:test:prepare
bundle exec rspec
```

If you see `socket "/tmp/.s.PGSQL.5432" failed`, add `TEST_NEON_DB` to `.env`.

## Commands

Do not run commands unless explicitly requested.

```bash
bundle exec rspec
bundle exec rspec spec/models/event_spec.rb
```
