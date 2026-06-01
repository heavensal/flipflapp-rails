# Bugbot (PR reviews)

[Cursor Bugbot](https://cursor.com/docs/bugbot) reviews pull requests. It reads **`.cursor/BUGBOT.md` files only** — not `.cursor/rules/*.mdc`.

## File layout

| Path | When included |
|------|----------------|
| `.cursor/BUGBOT.md` | Every review (project-wide) |
| `app/models/.cursor/BUGBOT.md` | Changes under `app/models/` |
| `app/controllers/.cursor/BUGBOT.md` | Changes under `app/controllers/` |
| `app/views/.cursor/BUGBOT.md` | Changes under `app/views/` |
| `app/javascript/.cursor/BUGBOT.md` | Changes under `app/javascript/` |
| `spec/.cursor/BUGBOT.md` | Changes under `spec/` |

## Shared policies

Bugbot rules align with:

- [AGENTS.md](../AGENTS.md)
- [TESTING.md](TESTING.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [FRONTEND.md](FRONTEND.md)

Edit policy in `docs/` and `AGENTS.md` first; update `.cursor/BUGBOT.md` when PR review expectations change.

## Enable Bugbot

1. [Cursor dashboard](https://cursor.com/dashboard) → Bugbot → connect GitHub
2. Enable for `heavensal/flipflapp-rails`
3. Optional: require `Cursor Bugbot` check in branch protection

Manual run on a PR: comment `cursor review` or `bugbot run`.

Verbose debug: `cursor review verbose=true`

## Cursor Agent vs Bugbot

| | Cursor Agent | Bugbot |
|---|--------------|--------|
| Config | `.cursor/rules/*.mdc` | `.cursor/BUGBOT.md` |
| When | Chat, Composer, Agent mode | Pull requests |

Do not duplicate long rule blocks between the two; link to `docs/` instead.
