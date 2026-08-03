# FlipFlapp mobile Users / profile contract (`/api/v1`)

LLM-ready handoff for iOS/Android **me / public profile / profile edit**. Prefer this directory over Swagger UI when implementing Users.

| Bundle | Path |
|--------|------|
| **Users (this bundle)** | [`docs/mobile/users/`](./) — `openapi.json`, `errors.json`, `flows.json`, `client.json`, this file |
| Auth (JWT / confirm / reset) | [`docs/mobile/auth/`](../auth/) |
| EventTeams + Friendships | [`docs/api/v1/`](../../api/v1/) |
| Events companion | [`swagger/v1/mobile/`](../../../swagger/v1/mobile/) |

Domain: [DOMAIN.md](../../DOMAIN.md) → User. Human overview: [API.md](../../API.md).

Resource names only: `me`, `users`. **Never** invent `/profile`, `/account`, or `/players`.

## Core operationIds

| operationId | Method | Path | Response schema |
|-------------|--------|------|-----------------|
| `getCurrentUser` | `GET` | `/api/v1/me` | `CurrentUser` |
| `updateCurrentUser` | `PATCH` | `/api/v1/me` | `CurrentUser` |
| `getUser` | `GET` | `/api/v1/users/{id}` | `PublicUser` |

All three require `Authorization: Bearer <jwt>`. Users ops **never** issue JWT (Auth: `signIn` / `confirmUser` only).

## CurrentUser vs PublicUser

| Field | CurrentUser (`/me`) | PublicUser (`/users/{id}` + nested) |
|-------|---------------------|-------------------------------------|
| `id` | yes | yes |
| `email` | yes | **never** |
| `unconfirmed_email` | yes (nullable) | **never** |
| `first_name` | yes | yes |
| `last_name` | yes | yes |
| `username` | yes | yes |
| `role` | yes (`player` \| `admin`) | **never** |
| `avatar_url` | yes (nullable URI) | yes (nullable URI) |

Same person may appear as `PublicUser` when nested on Friendship / EventParticipant / Invitation / search. Only `/me` exposes email, role, and pending email.

`role: admin` is informational — **no mobile admin API** in MVP; ignore for player UX.

## Writability (`PATCH /me`)

| Field | GET `/me` | PATCH | Notes |
|-------|-----------|-------|-------|
| `id` | R | — | |
| `email` | R | W | Reconfirmable; response keeps old `email` until Auth `confirmUser` |
| `unconfirmed_email` | R | — | Server-set after email PATCH; not writable |
| `first_name` / `last_name` | R | W | Presence required |
| `username` | R | — | Auto on create (`ada#0001`); **ignored** if sent |
| `role` | R | — | Ignored if sent |
| `avatar_url` | R | — | Response only |
| `avatar` | — | W | **Multipart file only** (`user[avatar]`) |
| `remove_avatar` | — | W | `true` clears photo |
| `password` / `password_confirmation` | — | W | No `current_password`; length 6..128 |

### JSON vs multipart

- `Content-Type: application/json` — text fields (+ optional `remove_avatar`).
- `Content-Type: multipart/form-data` — required for `user[avatar]` file; other fields as `user[first_name]` form parts.
- Do **not** send avatar as a JSON string.

Formats: **jpg, jpeg, gif, png**.

## Email change state machine

```text
PATCH /me { user: { email: new } }
  → 200 CurrentUser { email: old, unconfirmed_email: new }
  → user confirms via Auth confirmUser (token from email)
  → GET /me { email: new, unconfirmed_email: null }
```

## Password: `/me` vs Auth reset

| Flow | When | Ops | JWT |
|------|------|-----|-----|
| Logged-in change | User knows password / is signed in | `updateCurrentUser` with `password` + `password_confirmation` | **Stays valid** |
| Forgot password | Unauthenticated | Auth `requestPasswordReset` → `resetPassword` → `signIn` | Reset issues **no** JWT |

## Errors / offline

Shared nested shape: `{ "error": { "message", "details?" } }`.

| Status | Client |
|--------|--------|
| `401` | Clear session → Auth sign-in |
| `404` | Opaque missing (`getUser`) |
| `422` | Bind `details` (FR attribute strings); top-level often `"Validation failed"` |

Timeout / offline: do **not** optimistic-commit profile writes; retry on user action. Catalog: [`errors.json`](./errors.json).

## Flows

See [`flows.json`](./flows.json): `coldStartMe`, `editProfileNames`, `changeEmail`, `changePasswordLoggedIn`, `uploadAvatar`, `removeAvatar`, `openPublicProfileAddFriend`.

## Adjacent composition

- Friendship search returns `PublicUser[]` (`searchFriendshipCandidates`).
- Add friend from public profile: `getUser` → `createFriendship` (hub `friendships.profile_add_friend`).
- Compare Friendship nested users to `me.id` from `getCurrentUser`.

## Regenerate

```bash
bundle exec rake rswag:specs:swaggerize
bundle exec rake openapi:export          # also patches multipart user[avatar] on PATCH /me in JSON exports
bundle exec rake mobile:export_users_docs
```

Prefer the JSON handoffs in this directory over `swagger/v1/swagger.yaml` for multipart avatar field details (`user[avatar]` binary).
