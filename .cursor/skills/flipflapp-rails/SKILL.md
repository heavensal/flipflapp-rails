---
name: flipflapp-rails
description: >-
  Work on FlipFlapp Rails: TDD with RSpec, Hotwire/Stimulus, Tailwind 4,
  Kamal deploy. Use when changing models, controllers, specs, CI, or deploy config.
---

# FlipFlapp Rails skill

## Before coding

1. Read `AGENTS.md` and relevant `.cursor/rules/*.mdc`.
2. Identify affected routes in `config/routes.rb`.
3. For features: write failing **model** RSpec first (`spec/models/`).

## Tests

```bash
bundle exec rspec path/to/spec.rb
```

- Model-only: validations, uniqueness, CRUD side effects on data.
- Factory: `create(:user)`, `create(:event, user: user)`.
- No request/view specs for deploy gates.

## Deploy / CI

- Branch `master` triggers CI + Kamal in `.github/workflows/ci.yml`.
- Secrets template: `.kamal/secrets.cd` → copied in CI to `.kamal/secrets`.
- Manual deploy: `bin/kamal deploy` with local `.kamal/secrets`.

## Do not

- Commit secrets or amend git history unless asked.
- Add `pending` placeholder specs without a tracking issue.
