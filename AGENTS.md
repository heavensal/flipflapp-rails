# FlipFlapp Rails Agent Guide

FlipFlapp: football `Event` organizer MVP. Shared by **Cursor**, **Codex**, and **GitHub Copilot**.

Technical text in **English**. User-facing copy via I18n keys (`docs/I18N.md`).

## Workflow

1. [docs/PROJECT.md](docs/PROJECT.md) — scope
2. [docs/DOMAIN.md](docs/DOMAIN.md) — business rules
3. [docs/TESTING.md](docs/TESTING.md) — feature workflow (clarify → migrations if approved → specs → code)
4. [docs/RAILS_STYLEGUIDE.md](docs/RAILS_STYLEGUIDE.md) — Rails, RuboCop, &lt;150 lines
5. [docs/FRONTEND.md](docs/FRONTEND.md) — ERB, Tailwind, components, Stimulus

## Hard limits

- TDD: `spec/models/` for behavior changes
- No migrations, generators, commands, commit, or push unless explicitly requested
- No service objects unless explicitly requested
- Schema: `db/schema.rb` — migration policy below
- Config: plain `ENV["NAME"]` in `database.yml`; no ERB helpers unless asked

## Database and migrations

- Do not create migrations unless the user explicitly asks for a schema change.
- Propose migrations first; user validates before any `db/migrate/` file.
- When approved: migration + model validations + indexes + model specs.
- Do not run `db:migrate`, `db:prepare`, or generators unless explicitly asked.

## Security

- Never commit `.env`, `config/master.key`, `.kamal/secrets`, or credentials.
- Strong parameters on all controller writes; explicit auth in controllers.

## Git and deploy

- Production branch: `master`. User manages branches and PRs.
- Deploy: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

## Reference docs

| Topic | Doc |
|-------|-----|
| Product | [docs/PROJECT.md](docs/PROJECT.md) |
| Domain | [docs/DOMAIN.md](docs/DOMAIN.md) |
| TDD / features | [docs/TESTING.md](docs/TESTING.md) |
| Style | [docs/RAILS_STYLEGUIDE.md](docs/RAILS_STYLEGUIDE.md) |
| Commands | [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) |
| MVC layout | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| I18n | [docs/I18N.md](docs/I18N.md) |
| Frontend | [docs/FRONTEND.md](docs/FRONTEND.md) |
| Deploy | [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) |
| Routes | `config/routes.rb` |
| CI | `.github/workflows/ci.yml` |

## Tool entry points

| Tool | Config |
|------|--------|
| Cursor Agent | `.cursor/rules/flipflapp-rails.mdc` + [skill](.cursor/skills/flipflapp-rails/SKILL.md) |
| Cursor Bugbot (PR only) | `.cursor/BUGBOT.md` — commands: [docs/BUGBOT.md](docs/BUGBOT.md#commands) |
| GitHub Copilot | [.github/copilot-instructions.md](.github/copilot-instructions.md) |
| Codex prompts | [docs/CODEX_PLAYBOOK.md](docs/CODEX_PLAYBOOK.md) |

Layer context when editing: `app/models/AGENTS.md`, `app/controllers/AGENTS.md`, `app/views/AGENTS.md`, `app/javascript/AGENTS.md`, `spec/AGENTS.md`.

Do not duplicate long rule blocks outside `docs/` — link instead.
