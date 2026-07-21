# Bugbot — database layer

Also read: [.cursor/BUGBOT.md](../../.cursor/BUGBOT.md), [docs/TESTING.md](../../docs/TESTING.md), [AGENTS.md](../../AGENTS.md).

## No autofix

**Never Autofix** changes or findings that touch `db/**`:

- `db/migrate/**`
- `db/schema.rb`
- seeds / structure dumps under `db/`

Do not open an Autofix branch, commit to the PR branch, or rewrite these files via Cloud Agent.

## Review only

- Mark **❌ Issue** when migrations lack an explicit schema request in the PR title/description.
- Flag `schema.rb` version behind the latest migration file (pending-migration CI failure risk).
- Flag `change_column_null` / destructive changes without a safe backfill story.
- Suggest options in comments only; the author runs `bin/rails db:migrate` and commits the result.
