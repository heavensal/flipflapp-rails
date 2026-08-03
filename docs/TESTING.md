# Testing Policy

FlipFlapp uses **strict TDD**. This is the **directing workflow for every feature** — not an afterthought.

Business rules: [DOMAIN.md](DOMAIN.md). Run specs: [DEVELOPMENT.md](DEVELOPMENT.md). Agent policy: [AGENTS.md](../AGENTS.md).

---

## Feature workflow (TDD)

Use this sequence for every behavior change:

```
1. You describe what the feature must do
2. Agent reads DOMAIN.md, flags ambiguities and edge cases — you answer
3. DOMAIN.md updated if the rule is new or changed
4. Migrations proposed if needed — you validate before any migration file is created
5. Failing specs: model first; request/API specs when HTTP matters
6. Implement: model (validations + domain limits) → web controllers/views → /api/v1 controllers/serializers
7. If /api/v1 touched: OpenAPI + affected LLM-ready mobile bundle(s) in the SAME change (required)
8. Feature validation: PROJECT.md quality gates + API.md bundle checklist still match shipped behavior
```

Any change under `/api/v1` is **incomplete** until Step 7 is done. OpenAPI alone is not enough when flows, error catalogs, or CTAs change. See [API.md](API.md) Feature co-evolution and [docs/mobile/README.md](mobile/README.md).

### Step 1 — You describe the feature

Explain the expected behavior in product terms. Reference models when possible (`Event`, `Friendship`, `Notification`, etc.).

### Step 2 — Clarify before coding

The agent must read [DOMAIN.md](DOMAIN.md) and ask about:

- public vs private `Event`
- which `User` records can see, join, or invite
- which `EventTeam` / `EventParticipant` records change
- which `Notification` records are created or removed
- whether `role: admin` or a schema change is involved
- edge cases you care about

Do not start specs or code while behavior is still ambiguous.

### Step 3 — Domain doc

If the rule is new or changes MVP behavior, update [DOMAIN.md](DOMAIN.md) first (or in the same PR as the specs, after you confirm the rule).

### Step 4 — Migrations (only with your approval)

A feature request does **not** imply permission to migrate.

- If the feature needs a new column, table, or index, the agent **proposes** the migration and explains why.
- **You validate** the migration plan before any `db/migrate/` file is created.
- When approved: migration + model validations + indexes + model specs together.
- Do not run `bin/rails db:migrate` unless you explicitly ask.

Current schema: `db/schema.rb`.

### Step 5 — Red: specs

- Write or update specs in **`spec/models/`** first for domain rules.
- Add **`spec/requests/`** when the HTTP contract must be locked (status, auth, side effects exposed via endpoints).
- Add **`spec/requests/api/v1/`** (and rswag OpenAPI examples) when the JSON API contract changes.
- Specs describe **behavior** from [DOMAIN.md](DOMAIN.md), not implementation details.
- Use **Factory Bot** (`spec/factories/`). No YAML fixtures.
- No `pending` examples.
- Prefer `expect { }.to change` for `Notification` and record side effects.
- Prefer focused hand-written specs matching nearby files. Do not generate a model or scaffold merely to obtain a spec file.

Run (when you ask):

```bash
rspec spec/models/
rspec spec/requests/
rspec spec/requests/api/v1/
rspec spec/models/event_spec.rb
```

Uses `TEST_NEON_DB` — see [DEVELOPMENT.md](DEVELOPMENT.md).

### Step 6 — Green: implementation

1. **`app/models/`** — validations, domain limits, scopes, callbacks, methods (smallest change to pass specs).
2. **Controllers / views / Stimulus** — only to expose behavior already covered by model specs.
3. **JSON API (`/api/v1`)** — when the feature changes a mobile HTTP contract: update API controllers, serializers, `spec/requests/api/v1/`. Same domain rules as web; resource names match web (Convention over Configuration). See [API.md](API.md).

Refactor only when it makes the tested behavior clearer. No service objects unless you explicitly request them.

### Step 7 — Mobile documentation gate (required if `/api/v1` touched)

Touching any of `app/controllers/api/v1/`, API serializers, `config/routes.rb` `/api/v1`, or `spec/requests/api/v1/` **requires** in the same change:

1. rswag examples + regenerate OpenAPI (`bundle exec rake rswag:specs:swaggerize` → `bundle exec rake openapi:export`)
2. Update the affected LLM-ready companions (`errors.json`, `flows.json`, `client.json`, `CLIENT_CONTRACT.md` as applicable)
3. Re-export the owning bundle(s):

| Touches | Bundle | Export |
|---------|--------|--------|
| Auth session ops | [`docs/mobile/auth/`](mobile/auth/) | `mobile:export_auth_docs` |
| `me` / `users` | [`docs/mobile/users/`](mobile/users/) | `mobile:export_users_docs` |
| Events / participants / invitations | [`docs/mobile/events/`](mobile/events/) | `mobile:export_events_docs` |
| Notifications inbox | [`docs/mobile/notifications/`](mobile/notifications/) | `mobile:export_notifications_docs` |
| Device tokens | [`docs/mobile/device_tokens/`](mobile/device_tokens/) | `mobile:export_device_tokens_docs` |
| EventTeams / Friendships | [`docs/api/v1/`](api/v1/) | companions + `openapi:export` |

Index of all handoffs: [docs/mobile/README.md](mobile/README.md).

### Step 8 — Feature validation

Confirm [PROJECT.md](PROJECT.md) MVP quality gates and that every affected LLM bundle in [API.md](API.md) still matches shipped behavior. Feature incomplete if `/api/v1` changed but the matching bundle was not updated.

---

## Non-negotiable rules

- Model specs **before** (or with) behavior changes — never specs after the fact.
- **`spec/models/`** and **`spec/requests/`** only — no view, helper, system, or feature specs.
- Factory Bot only; no YAML fixtures; no `pending` examples.
- Agents do **not** run `rspec`, `db:migrate`, or other commands unless you explicitly ask.
- Any `/api/v1` change must update the matching LLM-ready mobile bundle in the same change ([API.md](API.md)).

---

## What to test

Specs lock **backend behavior** from [DOMAIN.md](DOMAIN.md). They are the source of truth for the iOS and Android JSON API — same rules, same side effects.

**`spec/models/`** — domain rules and data side effects:

- validations and uniqueness
- associations that enforce rules
- callbacks and data side effects
- `Notification` creation and cleanup
- `Friendship` and `Event` visibility / access rules
- `EventParticipant` and `EventTeam` (`slot`, `label`) rules
- data integrity after create, update, and destroy

**`spec/requests/`** — HTTP contract when it matters:

- authentication and authorization (who can call an endpoint)
- successful and rejected writes (e.g. join rejected when full)
- backend side effects visible through the API (records created or destroyed)

**`spec/requests/api/v1/`** — JSON API contract + OpenAPI (rswag):

- Bearer JWT auth, status codes, JSON shapes
- Resource names identical to web (`event_participants`, not aliases)
- Regenerate `swagger/v1/swagger.yaml` after OpenAPI examples change, then `bundle exec rake openapi:export`
- LLM-ready mobile bundles: [docs/mobile/README.md](mobile/README.md) — OpenAPI alone is not enough when flows/errors/CTAs change

Example: accepting a `Friendship` request **creates a `Notification`** → test in model or request spec.  
Example: a **flash message** after the action → do **not** test; verify visually in the browser.

## What not to test

- **Views and front-end** — HTML layout, ERB structure, CSS, Tailwind classes, Stimulus display behavior
- **Visually verifiable UI** — flash messages, button labels, page copy, redirect targets you can see in the browser
- **Helpers** — formatting helpers, presentation-only code
- **System / feature specs** — no Capybara or browser-driven tests

When in doubt: if the behavior is **data the mobile apps will need** (records, fields, kinds, access rules), test it. If it is **only how the web page looks or reads**, do not test it.

---

## Spec style

- One spec file per model (`spec/models/event_spec.rb`, etc.).
- `describe` blocks by behavior: `"validations"`, `"notifications"`, `"access rules"`.
- `create` / `build` from factories; traits for meaningful variants.
- Test names state the business rule in plain language.

---

## Read next

| Need | Doc |
|------|-----|
| Business rules | [DOMAIN.md](DOMAIN.md) |
| JSON API | [API.md](API.md) |
| Mobile LLM index | [mobile/README.md](mobile/README.md) |
| Commands | [DEVELOPMENT.md](DEVELOPMENT.md) |
| Migrations policy | [AGENTS.md](../AGENTS.md) |
