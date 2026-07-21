# Rails Styleguide

Default: **match the existing codebase**. Read a nearby file in the same layer before adding code.

| Topic | Doc |
|-------|-----|
| Business rules | [DOMAIN.md](DOMAIN.md) |
| Feature workflow (TDD) | [TESTING.md](TESTING.md) |
| Frontend (ERB, Tailwind, Stimulus, components) | [FRONTEND.md](FRONTEND.md) |
| Agent policy | [AGENTS.md](../AGENTS.md) |
| I18n | [I18N.md](I18N.md) |
| Local commands | [DEVELOPMENT.md](DEVELOPMENT.md) |

---

## Conventions

- **Rails** — standard MVC, RESTful controllers, Active Record patterns already in `app/`.
- **Senior Rails judgment** — make invariants explicit, keep writes atomic, avoid callback chains that hide control flow, prevent N+1 queries on collection pages, and use database constraints to back important model validations when schema work is approved.
- **Framework first** — use installed Rails/framework APIs before custom code. Identify a relevant generator or framework command before hand-writing boilerplate; propose it for approval rather than running it automatically.
- **Smallest design** — start with a model method, scope, association, validation, concern, controller action, partial, or job already supported by the architecture. Do not introduce a new layer for hypothetical reuse.
- **RuboCop** — follow [RuboCop Rails Omakase](https://github.com/rails/rubocop-rails-omakase); run `bin/rubocop` before considering a change done (when the user asks).
- **File size** — keep files **under 150 lines**. Split when a file grows past that (extract partial, private methods, or a focused class — not a service object unless requested).
- **English** — code, comments, commits, and technical docs.

---

## Layers (short)

| Layer | Rule |
|-------|------|
| `app/models/` | Domain behavior — [DOMAIN.md](DOMAIN.md), specs in `spec/models/` |
| `app/controllers/` | Thin: auth, strong params, delegate to models |
| `app/views/` | [FRONTEND.md](FRONTEND.md) |
| `app/javascript/` | [FRONTEND.md](FRONTEND.md) + [app/javascript/AGENTS.md](../app/javascript/AGENTS.md) |

## Implementation review

Before considering code complete, verify:

- the public API reads like the domain language in [DOMAIN.md](DOMAIN.md);
- authorization is explicit and cannot be bypassed by crafted parameters;
- multi-record writes cannot leave partial state;
- queries used by lists preload required associations;
- errors use model validation/I18n rather than duplicated controller strings;
- the change follows an existing local pattern or documents why a different Rails-native pattern is necessary;
- no new abstraction, dependency, JavaScript, CSS, or configuration surface was added without need and approval.

---

## Corrections log

Add a row when an agent (or human) repeats a mistake that must not happen again.

| Date | Don't | Do instead |
|------|-------|------------|
| | | |
