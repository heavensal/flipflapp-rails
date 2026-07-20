# Deployment

FlipFlapp production runs at **https://flipflapp.fr**. Deploys are automated from **`master`** via GitHub Actions and [Kamal](https://kamal-deploy.org/).

Local setup: [DEVELOPMENT.md](DEVELOPMENT.md). Agent policy: do not run deploy commands unless explicitly asked.

---

## Environments

Rails uses three environments. Each has its own database URL and secret storage.

| Rails env | Purpose | Database URL variable | Where secrets live |
|-----------|---------|----------------------|-------------------|
| `development` | Local app (`bin/dev`, console) | `DEVELOPMENT_NEON_DB` | `.env` (gitignored) |
| `test` | RSpec (`rspec`) | `TEST_NEON_DB` | `.env` locally; ephemeral Postgres in CI |
| `production` | Live app at `flipflapp.fr` | `PRODUCTION_NEON_DB` | `.kamal/secrets` (local deploy) or GitHub **environment `production`** (CI deploy) |

**Kamal does not read `.env`.** Production secrets for containers come from `.kamal/secrets` (or CI-generated secrets from GitHub).

Wiring: `config/database.yml` — plain `ENV["…"]` keys matching `.env.example`.

---

## Neon (PostgreSQL)

All environments use **Neon** serverless Postgres in production and local dev. Use **separate** Neon databases (or branches) per environment — never point development or test at production data.

| Variable | Environment | Notes |
|----------|-------------|-------|
| `DEVELOPMENT_NEON_DB` | `development` | Required in `.env` for local work |
| `TEST_NEON_DB` | `test` | Required in `.env` for local specs |
| `PRODUCTION_NEON_DB` | `production` | Injected into the Kamal container; not needed in local `.env` unless you deploy from your machine |

Production uses a single Postgres database (`PRODUCTION_NEON_DB`), including Solid Queue / Solid Cable tables.

### CI test job vs Neon

The **test** CI job does **not** call Neon. It uses a **temporary Postgres 16** service container and sets:

```text
TEST_NEON_DB=postgres://postgres:postgres@localhost:5432/flipflapp_test
```

Local specs still use your Neon `TEST_NEON_DB` from `.env`.

---

## CI/CD (GitHub Actions)

Workflow: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

### Triggers

| Event | Jobs that run |
|-------|----------------|
| Pull request | `scan_ruby`, `lint`, `test` |
| Push to `master` | Same three jobs, then **`deploy`** if all pass |

### Jobs

| Job | Command | Purpose |
|-----|---------|---------|
| `scan_ruby` | `bin/brakeman --no-pager` | Security scan |
| `lint` | `bin/rubocop -f github` | Style (RuboCop Rails Omakase) |
| `test` | `bin/rails db:test:prepare` + `bundle exec rspec` | Model specs against CI Postgres |
| `deploy` | `bin/kamal deploy` | Production deploy (master only, after green CI) |

The deploy job targets the GitHub **environment `production`**. You can require manual approval under **Settings → Environments → production** before Kamal runs.

### Deploy job flow

1. Checkout, Ruby, Docker Hub login (`KAMAL_REGISTRY_PASSWORD`)
2. SSH agent with `SSH_PRIVATE_KEY`; `ssh-keyscan` the deploy host
3. Copy [`.kamal/secrets.cd`](../.kamal/secrets.cd) → `.kamal/secrets` (placeholders filled from GitHub secrets)
4. `bin/kamal lock release` (clear stale deploy lock)
5. `bin/kamal deploy` — build image, push to Docker Hub, rolling update on the server

---

## Background jobs & realtime (production)

Production uses **Solid Queue** (Active Job) and **Solid Cable** (Action Cable). Tables live on the primary Neon database (migration `CreateSolidQueueAndCableTables`).

On the single web host, Solid Queue runs **inside Puma** via `SOLID_QUEUE_IN_PUMA=true` (no dedicated Kamal `job` machine yet). Notification create/broadcast and Devise mail (`deliver_later`) are processed by that supervisor.

Live notification toasts use Turbo Streams over Solid Cable to the signed-in user’s stream.

---

## Kamal

Configuration: [`config/deploy.yml`](../config/deploy.yml)

| Setting | Value |
|---------|--------|
| Service | `flipflapp_rails` |
| Image | `adam1344/flipflapp_rails` (Docker Hub) |
| Host | `flipflapp.fr` (SSL via Kamal proxy / Let's Encrypt) |
| Server | `51.75.124.208` (SSH user `ubuntu`) |
| Registry auth | `KAMAL_REGISTRY_PASSWORD` |
| Jobs | Solid Queue in Puma (`SOLID_QUEUE_IN_PUMA`) |)

### Secrets injected into the container

Listed under `env.secret` in `deploy.yml` (values from `.kamal/secrets`):

- `RAILS_MASTER_KEY`
- `PRODUCTION_NEON_DB`
- `CLOUDINARY_*`
- `GOOGLE_MAPS_KEY` (Places autocomplete)
- `SMTP_*`

Persistent volume: `flipflapp_storage` → `/rails/storage` (Active Storage).

### Kamal files

| File | Role |
|------|------|
| `config/deploy.yml` | Service, servers, proxy, env, volumes |
| `.kamal/secrets` | Local deploy secrets (gitignored) — copy from [`.kamal/secrets.example`](../.kamal/secrets.example) |
| `.kamal/secrets.cd` | CI template; GitHub Actions copies it and substitutes env vars |

Local shortcut (reuse `.env` for manual deploy):

```bash
ln -sf "$(pwd)/.env" "$(pwd)/.kamal/secrets"
```

### Manual deploy

Only when you intend to push to production outside CI (or to debug Kamal):

```bash
cp .kamal/secrets.example .kamal/secrets   # fill PRODUCTION_NEON_DB and other values
bin/kamal deploy
```

Useful aliases (from `deploy.yml`):

| Command | Purpose |
|---------|---------|
| `bin/kamal console` | Production Rails console |
| `bin/kamal shell` | Bash in the running container |
| `bin/kamal logs` | Tail application logs |
| `bin/kamal dbc` | Database console |

---

## GitHub secrets (environment `production`)

Set with `gh secret set … --env production` or the repository **Settings → Environments → production**.

| Secret | Used for |
|--------|----------|
| `SSH_PRIVATE_KEY` | SSH to deploy server (`ubuntu@51.75.124.208`) |
| `KAMAL_REGISTRY_PASSWORD` | Docker Hub push/pull |
| `RAILS_MASTER_KEY` | Rails encrypted credentials |
| `PRODUCTION_NEON_DB` | Neon production database URL |
| `CLOUDINARY_CLOUD_NAME` | Avatar uploads |
| `CLOUDINARY_API_KEY` | |
| `CLOUDINARY_API_SECRET` | |
| `GOOGLE_MAPS_KEY` | Maps / Places autocomplete |
| `SMTP_USERNAME` | Devise confirmable email |
| `SMTP_PASSWORD` | |

Example (sync Neon URL from local secrets file):

```bash
gh secret set PRODUCTION_NEON_DB --env production --body "$(grep '^PRODUCTION_NEON_DB=' .kamal/secrets | cut -d= -f2-)"
```

Never commit `.env`, `.kamal/secrets`, or `config/master.key`.

---

## End-to-end flow

```text
PR → CI (Brakeman, RuboCop, RSpec on ephemeral Postgres)
merge to master → same CI → deploy job → Kamal → flipflapp.fr
                                                      ↓
                                            Neon (PRODUCTION_NEON_DB)
```

---

## Read next

| Need | Doc |
|------|-----|
| Local setup & commands | [DEVELOPMENT.md](DEVELOPMENT.md) |
| CI workflow source | `.github/workflows/ci.yml` |
| Kamal config | `config/deploy.yml` |
