# Development Guide

This document gives agents and contributors a compact map of the local project workflow.

## Database URLs (Neon)

Set in `.env` (see `.env.example`):

- `DEVELOPMENT_NEON_DB` — `bin/rails db:prepare`, `bin/dev`
- `TEST_NEON_DB` — `bundle exec rspec`
- `PRODUCTION_NEON_DB` — not used locally unless `RAILS_ENV=production`; required in `.kamal/secrets` for deploy

## Local Stack

- Rails 8
- PostgreSQL (Neon)
- Devise with confirmable
- Tailwind CSS 4
- esbuild
- Propshaft
- CarrierWave and Cloudinary
- RSpec and Factory Bot
- Docker and Kamal

## Common Commands

Do not run these commands unless the user explicitly asks.

```bash
bundle install
npm install
bin/rails db:prepare
bin/dev
bundle exec rspec
bin/rubocop
bin/brakeman --no-pager
```

## Editing Policy

- Prefer small, direct changes.
- Match existing file structure and naming.
- Do not create migrations unless explicitly requested.
- Do not run Rails generators unless explicitly requested.
- Do not commit, push, or create branches.
- Keep new technical documentation in English.

## Before Coding

For business features, clarify:

- the expected model behavior;
- the invalid states to reject;
- the records affected by create, update, and destroy;
- whether notifications should be created or removed;
- whether the existing schema is enough.

For frontend features, clarify:

- whether plain ERB and Tailwind are enough;
- whether Hotwire or Stimulus is desired;
- whether copy needs locale keys immediately.
