# Bugbot (PR reviews)

[Cursor Bugbot](https://cursor.com/docs/bugbot) reviews pull requests. It reads **`.cursor/BUGBOT.md` files only** — not `.cursor/rules/*.mdc`.

**Command cheat sheet:** [Commands](#commands) below.

## Commands

### GitHub PR — comment on the PR

Post as a **top-level PR comment** (not a reply thread unless noted).

| Command | What it does |
|---------|----------------|
| `cursor review` | Run a Bugbot review on this PR |
| `bugbot run` | Same as `cursor review` |
| `cursor review verbose=true` | Review + verbose logs and request ID (for support) |
| `bugbot run verbose=true` | Same as above |
| `@cursor remember [fact]` | Save a **learned rule** for future reviews on this repo |

**Automatic reviews:** Bugbot also runs on each PR update unless the [dashboard](https://cursor.com/dashboard) is set to *Run only when mentioned*.

### GitHub PR — from Bugbot inline comments

| Action | What it does |
|--------|----------------|
| **Fix in Cursor** | Open the finding in Cursor to fix locally |
| **Fix in Web** | Open a Cursor web agent on the finding |

This repo keeps **Autofix Off** in the dashboard — fixes are human-triggered, not auto-committed.

### Cursor IDE — before you push

Available in Cursor 3.7+ (chat / agent). Reviews branch diff vs base; syncs with PR Bugbot so the same diff is not reviewed twice.

| Command | What it does |
|---------|----------------|
| `/review-bugbot` | Pre-push Bugbot review (committed + uncommitted vs base branch) |
| `/review` | Same family of skill — pre-push review |

Ask the agent to review **only uncommitted** changes for a narrower diff.

### Do **not** use for Bugbot review

These route to a **Cloud Agent** (may edit the PR), not Bugbot:

| Avoid | Why |
|-------|-----|
| `@cursor please fix` | Cloud Agent interprets as work instructions |
| `@cursor bugbot review please` | Same — use `cursor review` instead |
| `@cursor fix …` | Agent task, not a review trigger |

Use `cursor review` or `bugbot run` for a review-only pass.

### Dashboard (team / repo)

| Setting | This repo |
|---------|-----------|
| **Autofix** | **Off** (recommended) — see [Autofix](#autofix-recommended-off) |
| **Run only when mentioned** | Optional — if enabled, only the PR comment commands above trigger a run |
| **Incremental review** | Optional — review only diff since last Bugbot run |

Setup: [Enable Bugbot](#enable-bugbot).

---

## Autofix (recommended: Off)

This repo prefers **review comments over automatic commits**.

1. [Cursor dashboard](https://cursor.com/dashboard) → Bugbot → **Autofix: Off**
2. Review via inline comments; use **Fix in Cursor** / **Fix in Web** when you want a human-triggered fix
3. Manual review: comment `cursor review` or `bugbot run` on the PR

When Autofix is enabled anyway, [.cursor/BUGBOT.md](../.cursor/BUGBOT.md) limits it to **trivial, unambiguous policy fixes**. **Never Autofix** anything under `db/**` (migrations, `schema.rb`, seeds) — review comments and options only. Design debates get **❌ Issue + options**, not silent rewrites.

Trigger a review (not a Cloud Agent): `cursor review` or `bugbot run` — full list in [docs/BUGBOT.md](BUGBOT.md#commands).

## File layout

| Path | When included |
|------|----------------|
| `.cursor/BUGBOT.md` | Every review (project-wide) |
| `db/.cursor/BUGBOT.md` | Changes under `db/` (no Autofix) |
| `app/models/.cursor/BUGBOT.md` | Changes under `app/models/` |
| `app/controllers/.cursor/BUGBOT.md` | Changes under `app/controllers/` |
| `app/views/.cursor/BUGBOT.md` | Changes under `app/views/` |
| `app/javascript/.cursor/BUGBOT.md` | Changes under `app/javascript/` |
| `spec/.cursor/BUGBOT.md` | Changes under `spec/` |

## Shared policies

Bugbot rules align with:

- [AGENTS.md](../AGENTS.md)
- [DOMAIN.md](DOMAIN.md)
- [TESTING.md](TESTING.md)
- [RAILS_STYLEGUIDE.md](RAILS_STYLEGUIDE.md)
- [FRONTEND.md](FRONTEND.md)

Edit policy in `docs/` and `AGENTS.md` first; update `.cursor/BUGBOT.md` when PR review expectations change.

## Enable Bugbot

1. Cursor dashboard → Bugbot → connect GitHub
2. Enable for `heavensal/flipflapp-rails`
3. Optional: require `Cursor Bugbot` check in branch protection

## Cursor Agent vs Bugbot

| | Cursor Agent | Bugbot |
|---|--------------|--------|
| Config | `.cursor/rules/*.mdc` | `.cursor/BUGBOT.md` |
| When | Chat, Composer, Agent mode | Pull requests |
| Fixes code | When you ask in chat | **Off by default** — see Autofix above |

Do not duplicate long rule blocks between the two; link to `docs/` instead.
