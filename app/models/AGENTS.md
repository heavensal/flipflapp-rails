# Models

Domain rules: [docs/DOMAIN.md](../../docs/DOMAIN.md). TDD: [docs/TESTING.md](../../docs/TESTING.md). PR: [.cursor/BUGBOT.md](../../.cursor/BUGBOT.md).

- Behavior in models; specs in `spec/models/` before implementation
- Express domain language with conventional Active Record associations, validations, scopes, transactions, and focused model methods
- Back critical validations with database constraints only after migration approval
- Check collection callers for N+1 queries; keep multi-record state changes atomic
- No migrations unless explicitly requested
- No service objects unless explicitly requested
- Callbacks that change data need model specs

Cursor: [.cursor/rules/models.mdc](../../.cursor/rules/models.mdc)
