# FlipFlapp Rails Agent Guide

FlipFlapp is a Rails app for organizing sports games with friends: events, teams, participants, friendships, notifications, and user profiles.

All new project documentation, code comments, branch names, commit messages, and technical text must be written in English. User-facing app content will be translated later through locale files.

## Core Rules

- Optimize for precise, small changes that match the existing Rails codebase.
- Use Rails-native MVC, RESTful controllers, strong parameters, ERB, and Tailwind CSS 4 first.
- Keep business logic in models unless the existing code clearly uses another pattern.
- Do not introduce service objects, interactors, presenters, decorators, or new architectural layers unless explicitly requested.
- Do not run shell commands, tests, servers, generators, migrations, formatters, linters, or security scanners unless the user explicitly asks.
- Do not commit, push, create branches, open pull requests, or inspect remote pull requests unless the user explicitly asks.

## Stack

- Rails 8, PostgreSQL, Devise with confirmable
- Hotwire, Turbo, Stimulus, Tailwind CSS 4, esbuild, Propshaft
- CarrierWave, Cloudinary, Ransack
- RSpec, Factory Bot, RuboCop Rails Omakase, Brakeman
- Docker and Kamal deployment to `flipflapp.fr`

## TDD Policy

This app is strict TDD.

- Start behavior changes by defining or updating model specs in `spec/models/`.
- Specs must describe the business rule, validation, database effect, callback, or data side effect being changed.
- Do not add request specs, view specs, helper specs, system specs, or display-only tests unless the user explicitly changes this policy.
- Use Factory Bot only. Do not add YAML fixtures.
- Do not leave pending examples without a linked issue or explicit user approval.
- If the expected behavior is ambiguous, ask for the test cases before implementing.

## Database And Migrations

- Do not create migrations unless the user explicitly asks for a migration, model, table, column, index, or schema change.
- A feature request does not imply permission to generate a model or migration.
- If a change seems to need a migration but the user did not ask for one, explain the need and ask first.
- When migrations are explicitly requested, also consider model validations, database indexes, uniqueness constraints, and model specs.
- Do not run `db:migrate`, `db:prepare`, `db:setup`, or generators unless explicitly asked.

## Frontend Policy

- Prefer Rails-native `html.erb` and Rails 8 view helpers/tags.
- Use Tailwind CSS 4 utilities first.
- Keep HTML simple and semantic.
- Use Hotwire, Turbo, or Stimulus only when the user asks for richer frontend behavior or when static ERB cannot reasonably handle the requested interaction.
- Do not add inline JavaScript to ERB when a Stimulus controller is appropriate.
- New Stimulus controllers belong in `app/javascript/controllers/` and must be registered in `app/javascript/controllers/index.js`.

## I18n Policy

- New user-facing app copy should be designed for translation.
- Prefer model-scoped translation files and keys when adding app content.
- Keep technical docs and developer-facing text in English.
- If translation scope is unclear, ask before adding broad locale structures.

## Security And Secrets

- Never commit or expose `.env`, `config/master.key`, `.kamal/secrets`, production credentials, API keys, or tokens.
- Treat Devise, authentication, file uploads, Cloudinary, and user data as sensitive.
- Keep authorization checks explicit in controllers.
- Use strong parameters for all controller writes.

## Git And Deployment

- The production branch is `master`.
- The user manages branches, pushes, pull requests, and PR checks manually.
- Pushes to `master` trigger CI and Kamal deployment when green.
- Do not suggest that a change is deploy-ready unless the user asked you to run the relevant checks and they passed.

## Reference Docs

- Development setup: `docs/DEVELOPMENT.md`
- Architecture and domain: `docs/ARCHITECTURE.md`
- Testing policy: `docs/TESTING.md`
- Frontend policy: `docs/FRONTEND.md`
- Codex workflow prompts: `docs/CODEX_PLAYBOOK.md`
- Deployment: `docs/DEPLOYMENT.md`
- Routes: `config/routes.rb`
- CI/CD: `.github/workflows/ci.yml`
- Kamal: `config/deploy.yml`

## Tool-specific guides

| Tool | Config | Purpose |
|------|--------|---------|
| Cursor Agent | `.cursor/rules/*.mdc` | IDE coding context |
| Cursor Bugbot | `.cursor/BUGBOT.md` + nested `**/.cursor/BUGBOT.md` | PR review only |
| GitHub Copilot | `.github/copilot-instructions.md` | Copilot chat/completions |
| Codex | This file + `docs/CODEX_PLAYBOOK.md` | CLI / Cloud agents |
| Bugbot (docs index) | `docs/BUGBOT.md` | Human setup guide for PR reviews |

Keep shared policies in `docs/` and `AGENTS.md`. Link from tool configs; do not duplicate long rule blocks.
