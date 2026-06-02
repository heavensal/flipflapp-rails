# FlipFlapp Rails — GitHub Copilot

Read [AGENTS.md](../AGENTS.md) first. Same rules apply to Copilot, Cursor Agent, and Codex.

## Core rules

- Technical text, comments, commits, and branch names in **English**.
- Strict TDD: model specs in `spec/models/` for business behavior.
- No migrations unless explicitly requested.
- Rails-native ERB and Tailwind CSS 4; Hotwire/Stimulus only when needed.
- No commit, push, branches, or PRs unless explicitly requested.

## Reference docs

| Topic | File |
|-------|------|
| Agent guide | [AGENTS.md](../AGENTS.md) |
| Architecture | [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) |
| Testing | [docs/TESTING.md](../docs/TESTING.md) |
| I18n | [docs/I18N.md](../docs/I18N.md) |
| Frontend | [docs/FRONTEND.md](../docs/FRONTEND.md) |
| Development | [docs/DEVELOPMENT.md](../docs/DEVELOPMENT.md) |
| Codex playbook | [docs/CODEX_PLAYBOOK.md](../docs/CODEX_PLAYBOOK.md) |
| Deployment | [docs/DEPLOYMENT.md](../docs/DEPLOYMENT.md) |

## Layer context

- Models: [app/models/AGENTS.md](../app/models/AGENTS.md)
- Views: [app/views/AGENTS.md](../app/views/AGENTS.md)
- JavaScript: [app/javascript/AGENTS.md](../app/javascript/AGENTS.md)
- Specs: [spec/AGENTS.md](../spec/AGENTS.md)

## Pull requests

Human and Bugbot reviews follow [.cursor/BUGBOT.md](../.cursor/BUGBOT.md). Model changes require `spec/models/` updates. Do not add request/view specs by default.

## I18n

Create new translation files as `config/locales/<locale>/<feature>.yml`, for example `config/locales/fr/user.yml`. Do not create new `feature.fr.yml` or `feature.en.yml` files.
