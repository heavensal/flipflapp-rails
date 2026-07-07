# FlipFlapp Rails — GitHub Copilot

Read [AGENTS.md](../AGENTS.md) first. Same docs and workflow as Cursor Agent and Codex.

## Workflow

1. [docs/PROJECT.md](../docs/PROJECT.md) — scope
2. [docs/DOMAIN.md](../docs/DOMAIN.md) — business rules
3. [docs/TESTING.md](../docs/TESTING.md) — clarify → migrations (if approved) → specs → code
4. [docs/RAILS_STYLEGUIDE.md](../docs/RAILS_STYLEGUIDE.md) — Rails, RuboCop, &lt;150 lines
5. [docs/FRONTEND.md](../docs/FRONTEND.md) — ERB, Tailwind, components, Stimulus

## Hard limits

- TDD: `spec/models/` for behavior changes
- No migrations, commands, commit, or push unless explicitly requested
- No service objects unless explicitly requested
- **Ask before creating a new Stimulus controller**
- Stimulus: `app/javascript/controllers/<feature>/` — register in `index.js`

## Docs

| Topic | File |
|-------|------|
| Agent hub | [AGENTS.md](../AGENTS.md) |
| Domain | [docs/DOMAIN.md](../docs/DOMAIN.md) |
| TDD | [docs/TESTING.md](../docs/TESTING.md) |
| Style | [docs/RAILS_STYLEGUIDE.md](../docs/RAILS_STYLEGUIDE.md) |
| Commands | [docs/DEVELOPMENT.md](../docs/DEVELOPMENT.md) |
| MVC | [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) |
| I18n | [docs/I18N.md](../docs/I18N.md) |
| Frontend | [docs/FRONTEND.md](../docs/FRONTEND.md) |

## Layer context

- [app/models/AGENTS.md](../app/models/AGENTS.md)
- [app/controllers/AGENTS.md](../app/controllers/AGENTS.md)
- [app/views/AGENTS.md](../app/views/AGENTS.md)
- [app/javascript/AGENTS.md](../app/javascript/AGENTS.md)
- [spec/AGENTS.md](../spec/AGENTS.md)

## PR reviews

[.cursor/BUGBOT.md](../.cursor/BUGBOT.md) — model changes require `spec/models/` updates.
