# FlipFlapp Rails

Football `Event` organizer — Rails 8, PostgreSQL (Neon), Kamal → [flipflapp.fr](https://flipflapp.fr).

## Documentation

| Doc | Purpose |
|-----|---------|
| [AGENTS.md](AGENTS.md) | Agent hub (Cursor, Codex, Copilot) |
| [docs/PROJECT.md](docs/PROJECT.md) | Product scope |
| [docs/DOMAIN.md](docs/DOMAIN.md) | Business rules |
| [docs/TESTING.md](docs/TESTING.md) | TDD / feature workflow |
| [docs/RAILS_STYLEGUIDE.md](docs/RAILS_STYLEGUIDE.md) | Code style |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Local setup and commands |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Environments, Neon, CI/CD, Kamal |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | MVC layout |
| [docs/BUGBOT.md](docs/BUGBOT.md) | PR review (Bugbot) — **commands** |

## Bugbot (PR review)

Comment on a PR:

```text
cursor review          # run review
bugbot run             # same
cursor review verbose=true   # debug logs
```

Pre-push in Cursor: `/review-bugbot`. Full list: [docs/BUGBOT.md](docs/BUGBOT.md#commands).

## Quick start

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md):

```bash
bundle install
npm install
cp .env.example .env
bin/rails db:prepare
bin/dev
```
