---
applyTo: "spec/**/*"
---

# RSpec (model / data only)

Read [spec/AGENTS.md](../../spec/AGENTS.md) and [docs/TESTING.md](../../docs/TESTING.md).

- `spec/models/` only unless the user changes testing policy.
- Factory Bot (`create`, `build`); no YAML fixtures; no `pending` examples.
- Test validations, uniqueness, callbacks, and data side effects — not HTTP or HTML.
- PR policy: [.cursor/BUGBOT.md](../../.cursor/BUGBOT.md) and [spec/.cursor/BUGBOT.md](../../spec/.cursor/BUGBOT.md).
