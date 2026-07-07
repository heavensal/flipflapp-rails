# Bugbot — model layer

Also read: [docs/DOMAIN.md](../../../docs/DOMAIN.md), [docs/TESTING.md](../../../docs/TESTING.md), [app/models/AGENTS.md](../AGENTS.md).

Fix policy: [.cursor/BUGBOT.md](../../../.cursor/BUGBOT.md) — missing model spec = trivial if rule is clear; domain ambiguity = ❌ + options.

## Blocking checks

- Model behavior changes without **`spec/models/`** updates.
- Validations added in code without specs for valid/invalid cases.
- Callbacks that create or destroy related records without specs asserting DB/notification effects.
- Uniqueness rules without a spec proving duplicates are rejected.
- New migration in the same PR without explicit schema request in the PR description.

## Review focus

- `Friendship`: no self-friend; duplicate sender/receiver pairs; status transitions.
- `Event`: `start_time` in the future; default teams + author participant on create.
- `EventParticipant`: one user per event; join/leave notifications to event author.
- `EventTeam`: unique name per event.
- `Notification`: `kind` required; polymorphic targets consistent.

## Avoid suggesting

- Extracting service objects for simple Active Record logic.
- Request or view specs for model-only changes.
