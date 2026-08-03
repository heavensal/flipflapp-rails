# FlipFlapp mobile client contract (`/api/v1`)

LLM-ready shared rules for iOS/Android. Prefer this directory over Swagger UI when implementing clients.

| Bundle | Path |
|--------|------|
| EventTeams + Friendships (this hub) | [`docs/api/v1/`](./) — `openapi.json`, `errors.json`, `flows.json`, this file |
| Auth | [`docs/mobile/auth/`](../../mobile/auth/) |
| Users / profile | [`docs/mobile/users/`](../../mobile/users/) |
| Events / participants / invitations | [`docs/mobile/events/`](../../mobile/events/) |
| Notifications | [`docs/mobile/notifications/`](../../mobile/notifications/) |
| Device tokens | [`docs/mobile/device_tokens/`](../../mobile/device_tokens/) |

Mobile index: [`docs/mobile/README.md`](../../mobile/README.md).

Domain rules: [DOMAIN.md](../../DOMAIN.md). Human overview: [API.md](../../API.md).

`flows.json` is keyed by resource: `event_teams`, `friendships`.

## Headers

**Request (authenticated):**

- `Accept: application/json`
- `Content-Type: application/json` (when body present)
- `Authorization: Bearer <jwt>`

**Response:** Auth session issuers may return `Authorization: Bearer <jwt>` — only from `signIn` / `confirmUser`. EventTeams and Friendships ops never issue JWT.

## Resource names

Use CoC names only: `event_teams`, `event_participants`, `friendships`. **Never** invent `/teams`, `/participants`, `/friends`, `/requests`, or `/invitees` aliases.

## Error shape

All nested API errors:

```json
{ "error": { "message": "…", "details": { "field": ["…"] } } }
```

`details` appears on `422` validation failures. Message text follows server I18n (default locale **fr**). Friendships `403` is English `"Forbidden"`.

| Status | Client action |
|--------|----------------|
| `401` | Clear session → Auth sign-in |
| `403` | Show `error.message`; do not retry as another verb; do not treat as 404 |
| `404` | Opaque — missing **or** not viewable. Never prompt “request access” |
| `422` | Show `message` / bind `details` to fields; do not navigate as success |
| `204` | Empty body success — do not JSON-parse |

## Timeout / offline / no-response

- Do **not** optimistic-commit EventTeams rename/join/switch/leave **or** Friendships create/accept/decline/cancel/unfriend/remove-declined.
- On timeout or offline: leave local state unchanged; offer retry when online.
- Do not blindly auto-retry writes.

## EventTeams: `slot` vs `label` vs `countable`

| Field | Role |
|-------|------|
| `slot` | Immutable identity: `team_one` \| `team_two` \| `bench`. Capacity and notifications key off this. |
| `label` | Display name only (max 24; letters/digits/spaces). Renameable on countable teams. |
| `countable` | `true` for `team_one`/`team_two`; `false` for `bench`. Only countable teams count toward Event `participants_count`. |

UI: show `label`; keep `slot` for logic. Disable rename CTA when `countable == false` or viewer is not a participant.

Exactly **three** teams per event, created with the Event. **No** `POST` / `DELETE` `/event_teams`. **No** changing `slot` via API.

List order (`listEventTeams`): `team_one`, `team_two`, `bench`.

## Capacity (on Event, not EventTeam JSON)

Read-only on Event: `participants_count`, `spots_remaining`, `fill_level` — driven by countable slots. Bench never counts. Per-team full is enforced on join (`422`); EventTeam JSON does not expose `capacity` / `full`.

## EventTeams refetch matrix

| After | Refetch |
|-------|---------|
| `updateEventTeam` (rename) | Local update or `getEventTeam` / `listEventTeams` only — **not** participants |
| `joinOrSwitchEventParticipant` | `listEventTeamParticipants` for the **target** `event_team_id` only |
| Leave | `getEvent` (viewer flags) and/or refresh rosters as needed |

## Core EventTeams operationIds

| operationId | Method | Path |
|-------------|--------|------|
| `listEventTeams` | `GET` | `/api/v1/events/{event_id}/event_teams` |
| `getEventTeam` | `GET` | `/api/v1/events/{event_id}/event_teams/{id}` |
| `updateEventTeam` | `PATCH` | `/api/v1/events/{event_id}/event_teams/{id}` |

Adjacent roster: `listEventTeamParticipants`. Join/leave: `joinOrSwitchEventParticipant`, `deleteEventParticipant`.

## Friendships: status + role matrix

States: `pending` → `accepted` \| `declined`. From `declined`, receiver must `deleteFriendship` before either party can `createFriendship` again.

| Status | Sender UI | Receiver UI |
|--------|-----------|-------------|
| `pending` | In `sent`; cancel via `deleteFriendship` | In `received`; accept/decline via `updateFriendship` |
| `accepted` | In `accepted`; unfriend via `deleteFriendship` | Same |
| `declined` | Soft-ghosted — **no** declined bucket | In `declined`; remove via `deleteFriendship` only |

Index (`listFriendships`) always returns `{ accepted, sent, received, declined }` — empty arrays, never omitted keys. Nested `sender` / `receiver` are PublicUser (see [`docs/mobile/users/`](../../mobile/users/)); other user = compare `me.id` from `getCurrentUser` to `sender_id` / `receiver_id`.

**Destroy authz** (else `403` English `"Forbidden"`; success `204` empty):

| Status | Sender | Receiver |
|--------|--------|----------|
| pending | cancel OK | 403 |
| accepted | unfriend OK | unfriend OK |
| declined | 403 | remove OK |

**Update authz:** only receiver + pending may PATCH. Clients must send `{ "status": "accepted" }` or `{ "status": "declined" }`. Runtime trap: non-`declined` values take the accept branch.

**Create:** top-level `{ "user_id": 2 }` → `201` pending; side effect `friendship_requested` (inbox-hidden; push may still fire → friends/`received`, not notifications inbox).

**Search:** `GET /api/v1/friendships/search?q[first_name_or_last_name_or_username_cont]=…` — no email; blank/`q` missing → `[]`; excludes any existing friendship row. `avatar_url` typically null on search hits.

**Product:** accepted friendship ⇒ see friend’s private events + invite them. Pending/declined do not grant private visibility.

### Friendships refetch matrix

| After | Client action |
|-------|----------------|
| create / update / delete friendship | Refetch `listFriendships` (or patch local buckets) |
| search → create | Refresh search (target disappears) + `sent` |
| accept / decline | Refresh `received` (+ `accepted` or `declined`) |
| Push `friendship_requested` | Open friends / `received` — **not** notifications inbox |

### Invite picker (client composition)

`listFriendships.accepted` → derive other user per row → subtract `listEventParticipants` → subtract `listEventInvitations` → `createEventInvitations` with remaining `user_ids`. No `invitees` resource.

### Core Friendships operationIds

| operationId | Method | Path |
|-------------|--------|------|
| `listFriendships` | `GET` | `/api/v1/friendships` |
| `createFriendship` | `POST` | `/api/v1/friendships` |
| `searchFriendshipCandidates` | `GET` | `/api/v1/friendships/search` |
| `updateFriendship` | `PATCH` | `/api/v1/friendships/{id}` |
| `deleteFriendship` | `DELETE` | `/api/v1/friendships/{id}` |

See `flows.json` → `friendships` and `errors.json` → `friendship.*` for sequences and error catalogs.
