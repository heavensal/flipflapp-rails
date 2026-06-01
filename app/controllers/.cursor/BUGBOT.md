# Bugbot — controllers

Also read: [AGENTS.md](../../../AGENTS.md), [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).

## Blocking checks

- `create` / `update` / `destroy` without strong parameters.
- Mutations on events, friendships, or participants without `authenticate_user!` or explicit ownership checks.
- Mass assignment from raw `params` hashes.

## Review focus

- Authorization: only event author can edit/cancel; friendship actions limited to sender/receiver.
- N+1 queries on index actions (flag if obvious).
- Redirect/open redirects after auth actions.

## Tests

- Controller changes should be covered indirectly via **model specs** when domain rules change — not via new request specs unless policy changes.
