# Development Guide

> Local setup and commands to run FlipFlapp on your machine.

Product context: [PROJECT.md](PROJECT.md). Business rules: [DOMAIN.md](DOMAIN.md). TDD: [TESTING.md](TESTING.md). Production deploy: [DEPLOYMENT.md](DEPLOYMENT.md).

Agents: commands below are reference material, not standing permission to execute them. Propose the exact command and its effects; run it only when the user explicitly approves. Full policy: [AGENTS.md](../AGENTS.md).

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

API docs (Swagger UI): **http://localhost:3000/api-docs** — see [API.md](API.md).

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
- Solid Queue / Solid Cable tables live on the **primary** database (same Neon URL). Do **not** use a separate multi-db `queue`/`cable` role on that URL — `db:schema:load:queue` shares `schema_migrations` and wipes primary versions.
- `bin/dev` runs `jobs: bin/jobs` so notification delivery and Devise `deliver_later` mail run out of the web process.
- Mailers: always `deliver_later` (never `deliver_now` except console/debug). Devise confirmable/reset use Active Job automatically.

### Database

| Command | Purpose |
|---------|---------|
| `bin/rails db:prepare` | Create/migrate DB for current `RAILS_ENV` |
| `bin/rails db:migrate` | Run pending migrations (development) |
| `RAILS_ENV=test bin/rails db:migrate` | Apply pending migrations on Neon test DB (local) |
| `bin/rails db:test:prepare` | Prepare test DB before specs (CI ephemeral Postgres) |
| `bin/rails db:reset` | Drop, create, migrate, seed (destructive) |

### Tests & quality (CI runs these on `master`)

| Command | Purpose |
|---------|---------|
| `rspec` | Full model + request spec suite (`TEST_NEON_DB` required) |
| `rspec spec/models/event_spec.rb` | Single file |
| `rspec spec/models/event_spec.rb:42` | Single example |
| `rspec spec/requests/api/v1/` | JSON API request specs |
| `bundle exec rake rswag:specs:swaggerize` | Regenerate `swagger/v1/swagger.yaml` |
| `bin/rubocop` | Style (CI: lint job) |
| `bin/brakeman --no-pager` | Security scan (CI: scan_ruby job) |

### Rails helpers

| Command | Purpose |
|---------|---------|
| `bin/rails console` | Rails console (development) |
| `bin/rails routes` | HTTP surface |
| `bin/rails db:schema:load` | Load `db/schema.rb` into empty DB |

### Generators (framework-first, approval required)

Before creating conventional Rails boilerplate manually, inspect available generators with `bin/rails generate` or the relevant installed framework documentation. Propose the narrowest command and list its expected output.

Examples—not permission to run them:

| Need | Command to propose |
|------|--------------------|
| Controller without unwanted assets/specs | `bin/rails generate controller NAME ACTIONS --skip-routes --no-helper --no-assets` |
| Background job | `bin/rails generate job NAMESPACE/NAME` |
| RSpec model/request file | Prefer a focused hand-written spec matching existing files; do not generate a model merely to obtain a spec |
| Schema change | Propose the migration shape first; generate only after explicit schema approval |

Review generated output immediately. Keep only files needed by the approved task, adapt naming to the existing architecture, and never run generated migrations automatically.

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
| JSON API | [API.md](API.md) |
| How to test (TDD) | [TESTING.md](TESTING.md) |
| Current schema | `db/schema.rb` |
| Deploy & prod secrets | [DEPLOYMENT.md](DEPLOYMENT.md) |
