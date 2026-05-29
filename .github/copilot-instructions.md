# FlipFlapp Rails — GitHub Copilot

Read `AGENTS.md` for full project context. Summary:

## Product

Rails 8 app for organizing sports events with friends (teams, participants, friendships, notifications). User-facing copy in French.

## When editing Ruby

- Prefer RSpec model specs (validations, CRUD data rules) with behavior changes — no view/request specs.
- Run `bundle exec rspec`, `bin/rubocop`, `bin/brakeman` before suggesting a PR is ready.
- Match RuboCop Rails Omakase (`.rubocop.yml`).

## When editing front-end

- Stimulus controllers under `app/javascript/controllers/`; register in `index.js`.
- Tailwind CSS 4 utilities; build with `npm run build:css`.
- Avoid inline JavaScript in ERB when a Stimulus controller fits.

## Security

- Never suggest committing secrets, `master.key`, or `.kamal/secrets`.
- Use strong parameters; keep authorization checks in controllers.

## Deploy

Production deploys on push to `master` via GitHub Actions + Kamal (`config/deploy.yml`).
