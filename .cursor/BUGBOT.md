# FlipFlapp — Bugbot PR review rules

Source of truth for coding standards: [AGENTS.md](../AGENTS.md) and [docs/](../docs/).

Review in English. Focus on **bugs, data integrity, security, and policy violations** — not style nitpicks RuboCop already covers.

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
- When migrations are present, check for: matching model validations, indexes for uniqueness, and model specs for the new constraints.

## Security (always check)

- **Block** any diff that adds or exposes: `.env`, `config/master.key`, `.kamal/secrets`, tokens, API keys, or production credentials.
- Flag missing authorization on mutations (create/update/destroy) for events, friendships, event participants, user data.
- Flag unsafe mass assignment (params not permitted via strong parameters).
- Review Devise, Cloudinary/CarrierWave, and user PII handling carefully.

## Frontend (flag, usually non-blocking)

Policy: [docs/FRONTEND.md](../docs/FRONTEND.md)

- Flag inline JavaScript in ERB when Stimulus would be the local pattern.
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
