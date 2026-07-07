# Models

Domain rules: [docs/DOMAIN.md](../../docs/DOMAIN.md). TDD: [docs/TESTING.md](../../docs/TESTING.md). PR: [.cursor/BUGBOT.md](../../.cursor/BUGBOT.md).

- Behavior in models; specs in `spec/models/` before implementation
- No migrations unless explicitly requested
- No service objects unless explicitly requested
- Callbacks that change data need model specs

Cursor: [.cursor/rules/models.mdc](../../.cursor/rules/models.mdc)
