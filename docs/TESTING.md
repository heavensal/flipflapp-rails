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
5. Failing model specs written in spec/models/
6. Implementation until specs pass (model first, then controllers / views / API as needed)
```

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

### Step 5 — Red: model specs

- Write or update specs in **`spec/models/`** only.
- Specs describe **behavior** from [DOMAIN.md](DOMAIN.md), not implementation details.
- Use **Factory Bot** (`spec/factories/`). No YAML fixtures.
- No `pending` examples.
- Prefer `expect { }.to change` for `Notification` and record side effects.

Run (when you ask):

```bash
rspec spec/models/
rspec spec/models/event_spec.rb
```

Uses `TEST_NEON_DB` — see [DEVELOPMENT.md](DEVELOPMENT.md).

### Step 6 — Green: implementation

1. **`app/models/`** — smallest change to pass specs (validations, scopes, callbacks, methods).
2. **Controllers / views / Stimulus** — only to expose behavior already covered by model specs.
3. **JSON API** — after web flows, same domain rules and specs as source of truth.

Refactor only when it makes the tested behavior clearer. No service objects unless you explicitly request them.

---

## Non-negotiable rules

- Model specs **before** (or with) behavior changes — never specs after the fact.
- **`spec/models/`** only — no request, view, helper, or system specs unless you change this policy.
- Factory Bot only; no YAML fixtures; no `pending` examples.
- Agents do **not** run `rspec`, `db:migrate`, or other commands unless you explicitly ask.

---

## What to test

Model specs should lock [DOMAIN.md](DOMAIN.md) behavior:

- validations and uniqueness
- associations that enforce rules
- callbacks and data side effects
- `Notification` creation and cleanup
- `Friendship` and `Event` visibility / access rules
- `EventParticipant` and `EventTeam` (`slot`, `label`) rules
- data integrity after create, update, and destroy

## What not to test by default

- HTML layout, CSS, view rendering
- request routing, controller status codes
- helper formatting, JavaScript display behavior

Add these only if you explicitly change the policy for a task.

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
| Commands | [DEVELOPMENT.md](DEVELOPMENT.md) |
| Migrations policy | [AGENTS.md](../AGENTS.md) |
