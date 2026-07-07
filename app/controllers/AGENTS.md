# Controllers

Thin HTTP layer. Domain: [docs/DOMAIN.md](../../docs/DOMAIN.md). Style: [docs/RAILS_STYLEGUIDE.md](../../docs/RAILS_STYLEGUIDE.md). PR: [.cursor/BUGBOT.md](../../.cursor/BUGBOT.md).

- `before_action` auth; strong parameters; delegate rules to models
- No business logic in controllers
- No migrations unless explicitly requested

Cursor: [.cursor/rules/controllers.mdc](../../.cursor/rules/controllers.mdc)
