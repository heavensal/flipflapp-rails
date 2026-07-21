# Controllers

Thin HTTP layer. Domain: [docs/DOMAIN.md](../../docs/DOMAIN.md). Style: [docs/RAILS_STYLEGUIDE.md](../../docs/RAILS_STYLEGUIDE.md). PR: [.cursor/BUGBOT.md](../../.cursor/BUGBOT.md).

- `before_action` auth; strong parameters; delegate rules to models
- No business logic in controllers
- Use RESTful actions and existing routes; explicitly scope record lookup to what the current user may access
- Never trust IDs, ownership, roles, team slots, or state supplied by params without domain authorization
- No migrations unless explicitly requested

Cursor: [.cursor/rules/controllers.mdc](../../.cursor/rules/controllers.mdc)
