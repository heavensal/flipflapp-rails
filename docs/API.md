# FlipFlapp JSON API (`/api/v1`)

JSON API for iOS/Android clients. The web UI stays on session Devise; this API uses **Bearer JWT** (`devise-jwt`).

Domain rules: [DOMAIN.md](DOMAIN.md). Feature workflow: [TESTING.md](TESTING.md). Interactive docs: **http://localhost:3000/api-docs** (Swagger UI).

**Mobile Auth handoff (LLM-ready):** [`docs/mobile/auth/`](mobile/auth/) — `openapi.json`, `errors.json`, `flows.json`, `client.json`. Prefer that bundle over Swagger UI when implementing iOS/Android Auth.

**Mobile Users / profile handoff (LLM-ready):** [`docs/mobile/users/`](mobile/users/) — `openapi.json`, `errors.json`, `flows.json`, `client.json`, `CLIENT_CONTRACT.md`.

**Mobile Events handoff (LLM-ready):** [`docs/mobile/events/`](mobile/events/) — Events CRUD, participants, invitations.

**Mobile Notifications handoff (LLM-ready):** [`docs/mobile/notifications/`](mobile/notifications/).

**Mobile DeviceTokens handoff (LLM-ready):** [`docs/mobile/device_tokens/`](mobile/device_tokens/).

**Mobile EventTeams + Friendships handoff (LLM-ready):** [`docs/api/v1/`](api/v1/) — `openapi.json`, `errors.json`, `flows.json`, `CLIENT_CONTRACT.md`.

**Index of all mobile bundles:** [`docs/mobile/README.md`](mobile/README.md).

## Conventions

- **Convention over Configuration** — resource names match the web app and Active Record: `events`, `event_teams`, `event_participants`, `friendships`, `invitations`, `notifications`, `users`, `me`.
- Do **not** invent aliases (`teams`, `participants`, `invitees`, `auth`).
- JSON keys match model attributes / associations (`event_team_id`, `user_id`, `slot`, …).
- Controllers live under `app/controllers/api/v1/` and mirror web controller names.
- Domain logic stays in models; API controllers only authenticate, authorize via model predicates, permit params, and serialize.

## Auth

### Session rules

1. JWT is issued only by **`signIn`** or **`confirmUser`** (response header `Authorization: Bearer <jwt>`).
2. Register never opens a session (ignore any `Authorization` on register if present).
3. Send `Authorization: Bearer <jwt>` on protected requests.
4. `signOut` revokes the token when present (`jwt_denylist`) and always returns `204`.
5. Tokens expire after 7 days. Optional secret: `DEVISE_JWT_SECRET_KEY` (falls back to `secret_key_base`). No refresh endpoint — re-`signIn`.

### Operations

| operationId | Method | Path | Notes |
|-------------|--------|------|--------|
| `registerUser` | `POST` | `/api/v1/users` | Unconfirmed account + confirmation email; `201` `CurrentUser`; **no JWT** |
| `signIn` | `POST` | `/api/v1/users/sign_in` | Confirmed user only; `200` + `Authorization` |
| `signOut` | `DELETE` | `/api/v1/users/sign_out` | `204` always; revokes JWT when Bearer present |
| `requestPasswordReset` | `POST` | `/api/v1/users/password` | Email reset instructions; `204` / `422` |
| `resetPassword` | `PATCH` | `/api/v1/users/password` | Token + new password; `204` (no JWT) → then `signIn` |
| `resetPasswordWithPut` | `PUT` | `/api/v1/users/password` | Alias of `resetPassword` |
| `resendConfirmation` | `POST` | `/api/v1/users/confirmation` | Resend instructions; `204` / `422` |
| `confirmUser` | `PATCH` | `/api/v1/users/confirmation` | `{ confirmation_token }` → `200` + JWT |
| `getCurrentUser` | `GET` | `/api/v1/me` | Bearer required; `CurrentUser` includes `unconfirmed_email` |
| `updateCurrentUser` | `PATCH` | `/api/v1/me` | Profile update; email **reconfirmable**; avatar via **multipart**; no `current_password` — see [`docs/mobile/users/`](mobile/users/) |
| `getUser` | `GET` | `/api/v1/users/:id` | `PublicUser` only (no email/role) |

Typical signup: `registerUser` → email token → `confirmUser` (JWT) → `POST /device_token`.  
Typical return visit: `signIn` → `POST /device_token`.  
Sign-out: `DELETE /device_token` then `signOut`.

## Errors

All Auth (and API) JSON errors use one nested shape:

```json
{ "error": { "message": "…", "details": { "field": ["…"] } } }
```

`details` is present for validation failures (`422`); often omitted for `401` / `403` / `404`.

| Status | Meaning |
|--------|---------|
| `401` | Missing/invalid JWT, bad credentials, or unconfirmed sign-in |
| `403` | Authenticated but not allowed |
| `404` | Missing **or** not viewable (private events) |
| `422` | Validation failed (`details` present) |
| `204` | Success with empty body — do not JSON-parse |

## Resources

### Events

**Mobile Events handoff (LLM-ready):** [`docs/mobile/events/`](mobile/events/) — prefer that bundle over Swagger UI for Events / participants / invitations.

| operationId | Method | Path |
|-------------|--------|------|
| `listEvents` | `GET` | `/api/v1/events` |
| `createEvent` | `POST` | `/api/v1/events` |
| `getEvent` | `GET` | `/api/v1/events/:id` |
| `updateEvent` | `PATCH` | `/api/v1/events/:id` |
| `deleteEvent` | `DELETE` | `/api/v1/events/:id` |

Index = visible upcoming only. Event JSON includes `current_user`: `{ participant, can_invite, author, invited }` for CTAs. Private / not viewable → `404` (not `403`). `price` / `latitude` / `longitude` are **numbers on write**, **strings on read**.

### Event teams & participants (granular for iOS)

**Mobile EventTeams handoff (LLM-ready):** [`docs/api/v1/`](api/v1/) — prefer that bundle for `event_teams` rename. Participants join/leave also documented in [`docs/mobile/events/`](mobile/events/).

| operationId | Method | Path |
|-------------|--------|------|
| `listEventTeams` | `GET` | `/api/v1/events/:event_id/event_teams` |
| `getEventTeam` | `GET` | `/api/v1/events/:event_id/event_teams/:id` |
| `updateEventTeam` | `PATCH` | `/api/v1/events/:event_id/event_teams/:id` |
| `listEventParticipants` | `GET` | `/api/v1/events/:event_id/event_participants` |
| `listEventTeamParticipants` | `GET` | `/api/v1/events/:event_id/event_teams/:event_team_id/event_participants` |
| `joinOrSwitchEventParticipant` | `POST` | `/api/v1/events/:event_id/event_participants` |
| `deleteEventParticipant` | `DELETE` | `/api/v1/event_participants/:id` |

Exactly three teams per event (`team_one`, `team_two`, `bench`) — **no** `POST`/`DELETE` `/event_teams`. List order is domain slot order. `slot` immutable; rename is `label` only on countable teams (bench / non-participant → `403`). Nested roster: unknown `event_team_id` → `404`.

Join / switch body: `{ "event_participant": { "event_team_id": 123 } }` — first join `201`, switch `200`.

**iOS pattern:** after join/switch, refetch only  
`/api/v1/events/:event_id/event_teams/:event_team_id/event_participants` — not the full event tree. After rename, do **not** refetch participants.

Invite picker: `listFriendships` (accepted) − `listEventParticipants` − `listEventInvitations`. No `invitees` resource.  
For each accepted Friendship, other user = `sender_id == me.id ? receiver : sender`.

### Invitations

**LLM contract:** [`docs/mobile/events/`](mobile/events/) (invite flows + errors).

| operationId | Method | Path |
|-------------|--------|------|
| `listEventInvitations` | `GET` | `/api/v1/events/:event_id/invitations` |
| `createEventInvitations` | `POST` | `/api/v1/events/:event_id/invitations` |

Create body: `{ "user_ids": [1, 2] }` (accepted friends only). Empty/ineligible → `422` `"No users to invite"`.

### Friendships

| operationId | Method | Path |
|-------------|--------|------|
| `listFriendships` | `GET` | `/api/v1/friendships` |
| `createFriendship` | `POST` | `/api/v1/friendships` |
| `searchFriendshipCandidates` | `GET` | `/api/v1/friendships/search` |
| `updateFriendship` | `PATCH` | `/api/v1/friendships/:id` |
| `deleteFriendship` | `DELETE` | `/api/v1/friendships/:id` |

Index returns `{ accepted, sent, received, declined }` (keys always present; `declined` is receiver-only).  
Create body: `{ "user_id": 2 }` (top-level). Update: `{ "status": "accepted" }` or `"declined"` (receiver + pending only).  
Destroy: sender cancels pending; either party unfriends accepted; receiver removes declined → `204`.  
Search: Ransack `q[first_name_or_last_name_or_username_cont]`; blank `q` → `[]`; no email.

LLM contract: [`docs/api/v1/`](api/v1/) (`CLIENT_CONTRACT.md`, `flows.json` → `friendships`, `errors.json` → `friendship.*`).

### Notifications

**LLM contract:** [`docs/mobile/notifications/`](mobile/notifications/).

| operationId | Method | Path |
|-------------|--------|------|
| `listNotifications` | `GET` | `/api/v1/notifications` |
| `readNotification` | `PATCH` | `/api/v1/notifications/:id/read` |
| `readAllNotifications` | `PATCH` | `/api/v1/notifications/read_all` |
| `deleteNotification` | `DELETE` | `/api/v1/notifications/:id` |

Inbox excludes `friendship_requested` (same as web). Friends-request UX = `listFriendships.received` badge. Push may still deliver `friendship_requested` — route to friendships screen, not the inbox.

### Device tokens (mobile push)

**LLM contract:** [`docs/mobile/device_tokens/`](mobile/device_tokens/).

| operationId | Method | Path |
|-------------|--------|------|
| `registerDeviceToken` | `POST` | `/api/v1/device_token` |
| `unregisterDeviceToken` | `DELETE` | `/api/v1/device_token` |

Body: `{ "device_token": { "token": "<fcm-token>", "platform": "android" } }` (`platform` optional on create, defaults to `android`; allowed: `android`, `ios`).  
Register after sign-in / confirm / FCM token refresh (**200** empty); unregister on sign-out (**204** idempotent). Re-registering the same token reassigns it to the current user.

## OpenAPI / testing

- Specs: `spec/requests/api/v1/`
- Generate OpenAPI: `bundle exec rake rswag:specs:swaggerize`
- Export JSON: `bundle exec rake openapi:export` → `swagger/v1/openapi.json` and `docs/api/v1/openapi.json`
- Artifacts: `swagger/v1/swagger.yaml`, `swagger/v1/openapi.json`, `docs/api/v1/`, `docs/mobile/*`
- Mobile exports: `mobile:export_auth_docs`, `mobile:export_users_docs`, `mobile:export_events_docs`, `mobile:export_notifications_docs`, `mobile:export_device_tokens_docs`
- Index: [`docs/mobile/README.md`](mobile/README.md)
- UI: `/api-docs`

## Versioning

- Current surface is **`v1`**. Breaking JSON/field/path changes require **`v2`**; do not silently break `v1`.
- Additive fields on existing resources are allowed in `v1` when documented.

## Feature co-evolution

When a feature changes behavior that mobile clients consume:

1. Update [DOMAIN.md](DOMAIN.md) if the rule changed
2. Model specs first ([TESTING.md](TESTING.md))
3. Update web if needed
4. Update `/api/v1` controllers, serializers, and `spec/requests/api/v1/` **in the same change**
5. Regenerate OpenAPI (`rswag:specs:swaggerize` → `openapi:export`)
6. **Required documentation gate:** update every affected LLM-ready bundle in the same change:
   - Auth → [`docs/mobile/auth/`](mobile/auth/) (+ `rake mobile:export_auth_docs`)
   - Users / me → [`docs/mobile/users/`](mobile/users/) (+ `rake mobile:export_users_docs`)
   - Events / participants / invitations → [`docs/mobile/events/`](mobile/events/) (+ `rake mobile:export_events_docs`)
   - Notifications → [`docs/mobile/notifications/`](mobile/notifications/) (+ `rake mobile:export_notifications_docs`)
   - Device tokens → [`docs/mobile/device_tokens/`](mobile/device_tokens/) (+ `rake mobile:export_device_tokens_docs`)
   - EventTeams / Friendships → [`docs/api/v1/`](api/v1/) (`errors.json`, `flows.json`, `CLIENT_CONTRACT.md`)
7. Feature incomplete if `/api/v1` behavior changed but the matching LLM bundle was not updated

Index: [docs/mobile/README.md](mobile/README.md). See also `app/controllers/api/AGENTS.md`.
