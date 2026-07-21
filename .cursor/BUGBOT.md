# FlipFlapp — Bugbot PR review rules

Human command reference: [docs/BUGBOT.md](../docs/BUGBOT.md#commands) (`cursor review`, `bugbot run`, `/review-bugbot`, …).

Source of truth for coding standards: [AGENTS.md](../AGENTS.md) and [docs/](../docs/).

Review in English. Focus on **bugs, data integrity, security, and policy violations** — not style nitpicks RuboCop already covers.

## How to respond (fixes vs issues)

**Default: review only.** Do not push commits, open autofix branches, or rewrite large parts of the PR.

Human setup: keep **Bugbot Autofix Off** in the [Cursor dashboard](https://cursor.com/dashboard) for this repo (see [docs/BUGBOT.md](../docs/BUGBOT.md)). Use inline comments and **Fix in Cursor** / **Fix in Web** links.

### Trivial fix (only when explicitly asked to fix)

Apply a **small patch** (roughly ≤10 lines, one file) when the violation is **unambiguous** and matches a written repo rule:

- Missing `spec/models/` change alongside `app/models/` behavior change
- Strong-params gap on a single permitted attribute
- Stimulus controller not registered in `index.js`
- Obvious secret/credential committed (revert the line — still flag the author)
- Clear policy violation with one obvious correction (e.g. new `spec/requests/` file → delete or move logic to model spec)

**Never** treat anything under `db/**` as trivial autofix (migrations, `schema.rb`, seeds, structure) — see [Migrations and schema](#migrations-and-schema-blocking-when-applicable).

Post the diff as a **suggested snippet** in a comment unless the human enabled Autofix and the fix fits this bucket.

### Debate / large change (no autofix)

When the finding needs **design or product judgment**, multiple approaches, or touches several layers:

- Mark **❌ Issue** (blocking if security, data integrity, or explicit policy breach).
- State the **rule** violated ([DOMAIN.md](../docs/DOMAIN.md), [TESTING.md](../docs/TESTING.md), etc.).
- List **2–3 solution options** with trade-offs — do **not** implement one silently.
- Examples: new service object, ambiguous domain rule, large refactor, any `db/**` / schema / migration issue, friendship/event visibility semantics.

### Severity

| Marker | Meaning |
|--------|---------|
| ❌ | Blocking — must resolve before merge |
| ⚠️ | Policy / quality — trivial fix OK if asked |
| 💬 | Discussion — options only, no code push |

## Architecture (must enforce)

- Rails MVC only. Flag new service objects, interactors, form objects, presenters, or decorators unless the PR description explicitly requests them.
- Domain rules belong in **models** (`app/models/`), not helpers or views.
- Controllers: strong parameters, explicit authorization for sensitive actions (events, friendships, participants, uploads).

## TDD / tests (blocking when applicable)

Policy: [docs/TESTING.md](../docs/TESTING.md)

- If the PR changes **`app/models/**`** (excluding comments-only), it **must** include matching changes in **`spec/models/**`**.
- Model specs must cover the business rule being changed (validations, uniqueness, callbacks, notification side effects).
- **Block** PRs that add `spec/requests/**`, `spec/views/**`, `spec/helpers/**`, or system/feature specs unless the PR explicitly documents a policy change.
- **Block** new `pending` examples in `spec/`.
- **Block** new YAML fixtures; Factory Bot only.

## Migrations and schema (blocking when applicable)

- **Block** new files under `db/migrate/` unless the PR title or description clearly requests a schema change.
- **Never autofix anything under `db/**`** (including `db/migrate/**`, `db/schema.rb`, seeds, structure dumps). No Autofix branch, no Cloud Agent rewrite, no silent `schema.rb` sync — humans prepare and review schema changes before push.
- On DB findings: mark **❌ Issue**, explain the rule, and list **options only** (e.g. run `bin/rails db:migrate` locally and commit `schema.rb`; backfill then `change_column_null`; drop an unapproved migration). Do not push a fix.
- When migrations are present, check for: matching model validations, indexes for uniqueness, `schema.rb` version matching the latest migration timestamp, and model specs for the new constraints.

## Security (always check)

- **Block** any diff that adds or exposes: `.env`, `config/master.key`, `.kamal/secrets`, tokens, API keys, or production credentials.
- Flag missing authorization on mutations (create/update/destroy) for events, friendships, event participants, user data.
- Flag unsafe mass assignment (params not permitted via strong parameters).
- Review Devise, Cloudinary/CarrierWave, and user PII handling carefully.

## Frontend (flag, usually non-blocking)

Policy: [docs/FRONTEND.md](../docs/FRONTEND.md) — components, Stimulus permission, npm.

- Flag inline JavaScript in ERB when Stimulus is the local pattern.
- Flag new Stimulus controllers without prior approval in the PR description.
- Flag new npm dependencies without justification.
- Do not require view/request tests (out of policy).

## Deployment / CI

- Do not suggest editing `.github/workflows/ci.yml` or Kamal config unless the PR is about deploy.
- Secrets for CI live in GitHub **environment `production`** — never in the repo.

## Sensitive domain areas

Require extra scrutiny (and model specs when behavior changes):

- Friendships (pending/accepted, self-friend, duplicates)
- Event participation uniqueness and team assignment
- Event lifecycle (create teams, author participant, cancel/update notifications)
- Notification creation and cleanup on destroy

## What not to comment on

- Tailwind class naming preferences
- Minor ERB formatting
- Missing request/view tests (intentionally excluded from CI)
