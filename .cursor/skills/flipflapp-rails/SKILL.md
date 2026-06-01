---
name: flipflapp-rails
description: >-
  FlipFlapp Rails: strict model TDD, Rails-native frontend, Kamal deploy.
  Use for models, controllers, views, Stimulus, specs, CI, or agent docs.
---

# FlipFlapp Rails skill

## Source of truth

1. [AGENTS.md](../../AGENTS.md) — shared with Codex and Copilot
2. [docs/](../../docs/) — architecture, testing, frontend, development, deploy
3. Layer [AGENTS.md](../../app/models/AGENTS.md) files under `app/models/`, `app/views/`, `app/javascript/`, `spec/`
4. Cursor rules: [.cursor/rules/](../rules/)
5. PR reviews (Bugbot): [.cursor/BUGBOT.md](../BUGBOT.md) — **not** `.cursor/rules/`

## Before coding

- Read the layer `AGENTS.md` for touched directories.
- Check [config/routes.rb](../../config/routes.rb) for HTTP surface.
- Behavior change → failing **model** spec first in `spec/models/`.

## TDD (CI gate)

```bash
bundle exec rspec spec/models/
```

- Factory Bot: `create(:user)`, `create(:event, user: user)`.
- No request/view/helper/system specs unless user changes policy.
- No migrations unless explicitly requested.

## Frontend

- ERB + Tailwind 4; Stimulus only when needed; register in `index.js`.
- See [docs/FRONTEND.md](../../docs/FRONTEND.md).

## Deploy

- `master` → [.github/workflows/ci.yml](../../.github/workflows/ci.yml) → Kamal
- [docs/DEPLOYMENT.md](../../docs/DEPLOYMENT.md)

## Do not

- Commit secrets; run git push/commit unless asked.
- Add service objects or pending specs without approval.
- Duplicate Bugbot rules into `.mdc` files — link to `BUGBOT.md` instead.
