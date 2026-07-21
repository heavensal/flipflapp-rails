# Specs

Workflow: [docs/TESTING.md](../docs/TESTING.md). Domain: [docs/DOMAIN.md](../docs/DOMAIN.md). PR: [.cursor/BUGBOT.md](../.cursor/BUGBOT.md).

- `spec/models/` and `spec/requests/` only — no view, helper, or system specs
- Factory Bot; no fixtures; no pending examples
- Specs describe business rules, not implementation
- Model specs come first; request specs cover authentication, authorization, status, and externally visible side effects only
- Include rejection and boundary cases for permissions, capacity, uniqueness, and notification side effects

Cursor: [.cursor/rules/rspec.mdc](../.cursor/rules/rspec.mdc)
