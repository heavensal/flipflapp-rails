# FlipFlapp JSON API (`/api/v1`)

JSON API for iOS/Android clients. The web UI stays on session Devise; this API uses **Bearer JWT** (`devise-jwt`).

Domain rules: [DOMAIN.md](DOMAIN.md). Feature workflow: [TESTING.md](TESTING.md). Interactive docs: **http://localhost:3000/api-docs** (Swagger UI).

## Conventions

- **Convention over Configuration** — resource names match the web app and Active Record: `events`, `event_teams`, `event_participants`, `friendships`, `invitations`, `notifications`, `users`, `me`.
- Do **not** invent aliases (`teams`, `participants`, `invitees`, `auth`).
- JSON keys match model attributes / associations (`event_team_id`, `user_id`, `slot`, …).
- Controllers live under `app/controllers/api/v1/` and mirror web controller names.
- Domain logic stays in models; API controllers only authenticate, authorize via model predicates, permit params, and serialize.

## Auth

1. `POST /api/v1/users/sign_in` with `{ "user": { "email", "password" } }`
2. Read `Authorization: Bearer <jwt>` from the response header
3. Send that header on subsequent requests
4. `DELETE /api/v1/users/sign_out` revokes the token (`jwt_denylist`)

Optional secret: `DEVISE_JWT_SECRET_KEY` (falls back to `secret_key_base`). Tokens expire after 7 days.

| Method | Path | Notes |
|--------|------|--------|
| `POST` | `/api/v1/users` | Registration (confirmable — confirm via email before JWT login) |
| `POST` | `/api/v1/users/sign_in` | Returns user JSON + `Authorization` header |
| `DELETE` | `/api/v1/users/sign_out` | Revoke JWT |
| `POST` | `/api/v1/users/password` | Request reset instructions |
| `PATCH` | `/api/v1/users/password` | Reset with token |
| `POST` | `/api/v1/users/confirmation` | Resend confirmation |
| `GET` | `/api/v1/me` | Current user |
| `PATCH` | `/api/v1/me` | Update profile (`user` strong params) |
| `GET` | `/api/v1/users/:id` | Public profile fields |

## Errors

```json
{ "error": { "message": "…", "details": { "field": ["…"] } } }
```

| Status | Meaning |
|--------|---------|
| `401` | Missing/invalid JWT or bad credentials |
| `403` | Authenticated but not allowed |
| `404` | Missing **or** not viewable (private events) |
| `422` | Validation failed (`details` present) |

## Resources

### Events

| Method | Path |
|--------|------|
| `GET` | `/api/v1/events` |
| `POST` | `/api/v1/events` |
| `GET` | `/api/v1/events/:id` |
| `PATCH` | `/api/v1/events/:id` |
| `DELETE` | `/api/v1/events/:id` |

`GET` show includes `current_user`: `{ participant, can_invite, author, invited }`.

### Event teams & participants (granular for iOS)

| Method | Path |
|--------|------|
| `GET` | `/api/v1/events/:event_id/event_teams` |
| `GET` | `/api/v1/events/:event_id/event_teams/:id` |
| `PATCH` | `/api/v1/events/:event_id/event_teams/:id` |
| `GET` | `/api/v1/events/:event_id/event_participants` |
| `GET` | `/api/v1/events/:event_id/event_teams/:event_team_id/event_participants` |
| `POST` | `/api/v1/events/:event_id/event_participants` |
| `DELETE` | `/api/v1/event_participants/:id` |

Join / switch team body: `{ "event_participant": { "event_team_id": 123 } }`.

**iOS pattern:** after a join, refetch only  
`/api/v1/events/:event_id/event_teams/:event_team_id/event_participants` — not the full event tree.

Invite picker: use `GET /api/v1/friendships` (accepted) plus existing `event_participants` / `invitations` — same idea as web `get_my_friends_but_not_participants`. No `invitees` resource.

### Invitations

| Method | Path |
|--------|------|
| `GET` | `/api/v1/events/:event_id/invitations` |
| `POST` | `/api/v1/events/:event_id/invitations` |

Create body: `{ "user_ids": [1, 2] }` (accepted friends only).

### Friendships

| Method | Path |
|--------|------|
| `GET` | `/api/v1/friendships` |
| `POST` | `/api/v1/friendships` |
| `PATCH` | `/api/v1/friendships/:id` |
| `DELETE` | `/api/v1/friendships/:id` |
| `GET` | `/api/v1/friendships/search` |

Index returns `{ accepted, sent, received, declined }`.  
Create: `{ "user_id": 2 }`. Update: `{ "status": "accepted" }` or `"declined"`.

### Notifications

| Method | Path |
|--------|------|
| `GET` | `/api/v1/notifications` |
| `PATCH` | `/api/v1/notifications/:id/read` |
| `PATCH` | `/api/v1/notifications/read_all` |
| `DELETE` | `/api/v1/notifications/:id` |

Inbox excludes `friendship_requested` (same as web).

## OpenAPI / testing

- Specs: `spec/requests/api/v1/`
- Generate OpenAPI: `bundle exec rake rswag:specs:swaggerize`
- Artifact: `swagger/v1/swagger.yaml`
- UI: `/api-docs`

## Versioning

- Current surface is **`v1`**. Breaking JSON/path changes require **`v2`**; do not silently break `v1`.
- Additive fields on existing resources are allowed in `v1` when documented.

## Feature co-evolution

When a feature changes behavior that mobile clients consume:

1. Update [DOMAIN.md](DOMAIN.md) if the rule changed
2. Model specs first ([TESTING.md](TESTING.md))
3. Update web if needed
4. Update **`/api/v1`** controllers, serializers, request specs, and OpenAPI **in the same change**

See also `app/controllers/api/AGENTS.md`.
