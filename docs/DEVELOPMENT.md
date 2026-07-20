# Development Guide

> Local setup and commands to run FlipFlapp on your machine.

Product context: [PROJECT.md](PROJECT.md). Business rules: [DOMAIN.md](DOMAIN.md). TDD: [TESTING.md](TESTING.md). Production deploy: [DEPLOYMENT.md](DEPLOYMENT.md).

Agents: do not run shell commands unless the user explicitly asks. Full policy: [AGENTS.md](../AGENTS.md).

---

## JavaScript

This project uses **npm** (`package-lock.json`). **Do not use yarn** — there is no `yarn.lock`.

```bash
npm install
```

Asset builds run via `npm` scripts (`Procfile.dev` → `npm run build`, `npm run build:css`).

---

## First-time setup

Prerequisites: Ruby (see `.ruby-version`), Node.js, a [Neon](https://neon.tech) account.

```bash
git clone <repo-url>
cd flipflapp-rails
bundle install
npm install
cp .env.example .env          # fill in local values (see below)
bin/rails db:prepare
bin/rails db:schema:load:queue
bin/rails db:schema:load:cable
bin/dev
```

Alternative one-shot setup (installs deps, prepares DB, starts `bin/dev`):

```bash
bin/setup
```

App URL: **http://localhost:3000** (override with `PORT=3001 bin/dev`).

---

## Neon (development + test)

Copy `.env.example` → `.env`. Wired in `config/database.yml`.

| Variable | Used for |
|----------|----------|
| `DEVELOPMENT_NEON_DB` | `RAILS_ENV=development` — `bin/dev`, `bin/rails db:*`, console |
| `TEST_NEON_DB` | `RAILS_ENV=test` — `rspec` |

Use **separate** Neon databases (or branches) for development and test. Never point local env at production.

For `TEST_NEON_DB`, prefer Neon’s **direct** host (not `-pooler`). Locally, Rails does not purge/rebuild the test DB on each `rspec` run (that triggers `PG::ObjectInUse` on Neon); apply schema with `RAILS_ENV=test bin/rails db:migrate`. CI still rebuilds the schema.

Production URL (`PRODUCTION_NEON_DB`) is for deploy only — see [DEPLOYMENT.md](DEPLOYMENT.md). Kamal does not read `.env`.

### Local `.env` (typical)

| Variable | Needed for local dev |
|----------|----------------------|
| `DEVELOPMENT_NEON_DB` | Yes |
| `TEST_NEON_DB` | Yes (specs) |
| `RAILS_MASTER_KEY` | Yes (encrypted credentials) |
| `CLOUDINARY_*` | Yes (avatar uploads) |
| `SMTP_*` | Yes (Devise confirmable emails) |
| `GOOGLE_MAPS_KEY` | Optional locally — Places autocomplete on event forms |
| `PRODUCTION_NEON_DB` | No — deploy secrets only |

---

## Commands (day one)

Prefer **`bin/…`** and direct gem binaries over `bundle exec` where available.

### Run the app

| Command | Purpose |
|---------|---------|
| `bin/dev` | Start Rails + JS + CSS watchers + Solid Queue worker (`Procfile.dev`) |
| `bin/jobs` | Solid Queue worker alone (also started by `bin/dev`) |
| `bin/setup` | Install deps, `db:prepare`, optional start `bin/dev` |

### Background jobs & realtime

- **Active Job** adapter: Solid Queue (development/production). Test uses `:test`.
- **Action Cable** adapter: Solid Cable (development/production). Test uses `:test`.
- Multi-db roles `queue` and `cable` share the same Neon URL as primary; schemas live in `db/queue_schema.rb` and `db/cable_schema.rb`.
- `bin/dev` runs `jobs: bin/jobs` so notification delivery and Devise `deliver_later` mail run out of the web process.
- Mailers: always `deliver_later` (never `deliver_now` except console/debug). Devise confirmable/reset use Active Job automatically.

### Database

| Command | Purpose |
|---------|---------|
| `bin/rails db:prepare` | Create/migrate primary for current `RAILS_ENV` |
| `bin/rails db:schema:load:queue` | Load Solid Queue tables (`db/queue_schema.rb`) |
| `bin/rails db:schema:load:cable` | Load Solid Cable tables (`db/cable_schema.rb`) |
| `bin/rails db:migrate` | Run pending migrations (development) |
| `bin/rails db:test:prepare` | Prepare test DB before specs |
| `bin/rails db:reset` | Drop, create, migrate, seed (destructive) |

### Tests & quality (CI runs these on `master`)

| Command | Purpose |
|---------|---------|
| `rspec` | Full model spec suite (`TEST_NEON_DB` required) |
| `rspec spec/models/event_spec.rb` | Single file |
| `rspec spec/models/event_spec.rb:42` | Single example |
| `bin/rubocop` | Style (CI: lint job) |
| `bin/brakeman --no-pager` | Security scan (CI: scan_ruby job) |

### Rails helpers

| Command | Purpose |
|---------|---------|
| `bin/rails console` | Rails console (development) |
| `bin/rails routes` | HTTP surface |
| `bin/rails db:schema:load` | Load `db/schema.rb` into empty DB |

### Dependencies

| Command | Purpose |
|---------|---------|
| `bundle install` | Ruby gems |
| `npm install` | JavaScript packages (**npm only** — not yarn) |

### Deploy (manual — not day one)

| Command | Purpose |
|---------|---------|
| `bin/kamal deploy` | Production deploy (requires `.kamal/secrets`) |

---

## Read next

| Need | Doc |
|------|-----|
| What to build | [DOMAIN.md](DOMAIN.md) |
| How to test (TDD) | [TESTING.md](TESTING.md) |
| Current schema | `db/schema.rb` |
| Deploy & prod secrets | [DEPLOYMENT.md](DEPLOYMENT.md) |
