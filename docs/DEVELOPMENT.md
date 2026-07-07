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

Production URL (`PRODUCTION_NEON_DB`) is for deploy only — see [DEPLOYMENT.md](DEPLOYMENT.md). Kamal does not read `.env`.

### Local `.env` (typical)

| Variable | Needed for local dev |
|----------|----------------------|
| `DEVELOPMENT_NEON_DB` | Yes |
| `TEST_NEON_DB` | Yes (specs) |
| `RAILS_MASTER_KEY` | Yes (encrypted credentials) |
| `CLOUDINARY_*` | Yes (avatar uploads) |
| `SMTP_*` | Yes (Devise confirmable emails) |
| `GOOGLE_*` | Optional — OAuth out of MVP scope |
| `PRODUCTION_NEON_DB` | No — deploy secrets only |

---

## Commands (day one)

Prefer **`bin/…`** and direct gem binaries over `bundle exec` where available.

### Run the app

| Command | Purpose |
|---------|---------|
| `bin/dev` | Start Rails + JS + CSS watchers (daily driver) |
| `bin/setup` | Install deps, `db:prepare`, optional start `bin/dev` |

### Database

| Command | Purpose |
|---------|---------|
| `bin/rails db:prepare` | Create/migrate DB for current `RAILS_ENV` |
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
