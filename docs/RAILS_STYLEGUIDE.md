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

---

## Corrections log

Add a row when an agent (or human) repeats a mistake that must not happen again.

| Date | Don't | Do instead |
|------|-------|------------|
| | | |
