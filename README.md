# FlipFlapp Rails

FlipFlapp is a Rails app for organizing sports games with friends.

## Stack

- Rails 8
- PostgreSQL
- Devise with confirmable
- Hotwire, Turbo, Stimulus
- Tailwind CSS 4
- esbuild and Propshaft
- CarrierWave and Cloudinary
- RSpec and Factory Bot
- Docker and Kamal

## Agent And Contributor Docs

- Agent guide: `AGENTS.md`
- Development: `docs/DEVELOPMENT.md`
- Architecture: `docs/ARCHITECTURE.md`
- Testing: `docs/TESTING.md`
- Frontend: `docs/FRONTEND.md`
- Codex playbook: `docs/CODEX_PLAYBOOK.md`
- Deployment: `docs/DEPLOYMENT.md`

## Local Commands

Do not run these commands unless you intend to change or verify the local environment.

```bash
bundle install
npm install
bin/rails db:prepare
bin/dev
bundle exec rspec
bin/rubocop
bin/brakeman --no-pager
```
