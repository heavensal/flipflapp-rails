# Bugbot — JavaScript / Stimulus

Also read: [docs/FRONTEND.md](../../../docs/FRONTEND.md), [app/javascript/AGENTS.md](../AGENTS.md).

Fix policy: [.cursor/BUGBOT.md](../../../.cursor/BUGBOT.md) — e.g. missing `index.js` registration = trivial; new controller without approval = ❌ + options.

## Review focus

- New Stimulus controllers **not** registered in `app/javascript/controllers/index.js`.
- Controllers doing server-side business logic instead of calling Rails endpoints.
- Fragile DOM selectors; prefer `data-*` targets.
- New npm dependencies without explicit need.

## Do not block for

- Missing JS tests (not in CI scope).
