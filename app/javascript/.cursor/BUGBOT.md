# Bugbot — JavaScript / Stimulus

Also read: [app/javascript/AGENTS.md](../AGENTS.md), [docs/FRONTEND.md](../../../docs/FRONTEND.md).

## Review focus

- New Stimulus controllers **not** registered in `app/javascript/controllers/index.js`.
- Controllers doing server-side business logic instead of calling Rails endpoints.
- Fragile DOM selectors; prefer `data-*` targets.
- New npm dependencies without explicit need.

## Do not block for

- Missing JS tests (not in CI scope).
