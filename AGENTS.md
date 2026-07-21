# FlipFlapp Rails Agent Guide

FlipFlapp: football `Event` organizer MVP. Shared by **Cursor**, **Codex**, and **GitHub Copilot**.

Technical text in **English**. User-facing copy via I18n keys (`docs/I18N.md`).

## Mission

Build the smallest production-quality Rails MVP that completely satisfies the documented football flows. Prefer correctness, data integrity, security, and a coherent web flow over abstractions, speculative extensibility, or out-of-scope features.

Codex must understand the task before editing. For every non-trivial change:

1. Read [docs/PROJECT.md](docs/PROJECT.md) for product scope and MVP quality gates.
2. Read the relevant section of [docs/DOMAIN.md](docs/DOMAIN.md) for business rules.
3. Inspect the current route, schema, nearby implementation, and existing specs.
4. Read the closest nested `AGENTS.md` for every file being changed.
5. State ambiguities, schema impact, and the smallest Rails-native approach before implementation.

## Workflow

1. [docs/PROJECT.md](docs/PROJECT.md) — scope and MVP completion gates
2. [docs/DOMAIN.md](docs/DOMAIN.md) — business rules
3. [docs/TESTING.md](docs/TESTING.md) — feature workflow (clarify → migrations if approved → specs → code → API if mobile contract changes)
4. [docs/RAILS_STYLEGUIDE.md](docs/RAILS_STYLEGUIDE.md) — Rails, RuboCop, &lt;150 lines
5. [docs/FRONTEND.md](docs/FRONTEND.md) — ERB, Tailwind, components, Stimulus
6. [docs/API.md](docs/API.md) — JSON `/api/v1` for mobile
7. [docs/CODEX_PLAYBOOK.md](docs/CODEX_PLAYBOOK.md) — Codex task protocol and permission matrix

## Hard limits

- TDD: `spec/models/` first for behavior changes; `spec/requests/` only for HTTP contracts
- Do not run commands, generators, migrations, commits, pushes, or deploys unless explicitly requested
- No service objects unless explicitly requested
- Schema: `db/schema.rb` — migration policy below
- Config: plain `ENV["NAME"]` in `database.yml`; no ERB helpers unless asked
- No feature expansion beyond the documented MVP without explicit approval

## Framework-first implementation

- Prefer Rails 8, Active Record, Devise (+ devise-jwt for `/api/v1`), Hotwire, Stimulus, Solid Queue, Solid Cable, Ransack, CarrierWave, Alba, and existing project APIs before custom infrastructure.
- Before hand-writing framework boilerplate, identify the installed framework generator or command that would create it.
- Because commands require approval, propose the exact command and expected files first. Run it only after the user approves.
- After an approved generator runs, remove unused output and adapt the result to project conventions. Never use a generator as permission for a migration.
- If no suitable generator exists, implement the smallest conventional Rails solution and explain that choice.

## Database and migrations

- Do not create migrations unless the user explicitly asks for a schema change.
- Propose migrations first; user validates before any `db/migrate/` file.
- When approved: migration + model validations + indexes + model specs.
- Do not run `db:migrate`, `db:prepare`, or generators unless explicitly asked.

## Frontend boundary

- ERB + Rails helpers + Tailwind CSS 4 are the default and only styling system.
- Do not introduce custom CSS, inline style attributes, another CSS framework, or a new visual language unless explicitly approved.
- Reuse nearby Tailwind patterns and existing partials before adding new markup.
- Ask before adding a Stimulus controller or npm dependency.

## Current documentation

- When changing Codex/OpenAI integrations, models, prompts, MCP servers, skills, plugins, or hooks, consult `openaiDeveloperDocs` first and fetch the exact current official page.
- For framework behavior, prefer the installed version, repository code, and official documentation over memory.

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
| JSON API | [docs/API.md](docs/API.md) |
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

Layer context when editing: `app/models/AGENTS.md`, `app/controllers/AGENTS.md`, `app/controllers/api/AGENTS.md`, `app/jobs/AGENTS.md`, `app/views/AGENTS.md`, `app/javascript/AGENTS.md`, `spec/AGENTS.md`.

Do not duplicate long rule blocks outside `docs/` — link instead.
