# FlipFlapp mobile Events contract (`/api/v1`)

LLM-ready handoff for Events CRUD, participants join/leave, and invitations. Prefer this directory over Swagger UI.

| Bundle | Path |
|--------|------|
| **Events (this)** | [`docs/mobile/events/`](./) |
| EventTeams rename | [`docs/api/v1/`](../../api/v1/) |
| Friendships / invite picker | [`docs/api/v1/`](../../api/v1/) |
| Users (PublicUser) | [`docs/mobile/users/`](../users/) |
| Notifications | [`docs/mobile/notifications/`](../notifications/) |
| Auth | [`docs/mobile/auth/`](../auth/) |

Domain: [DOMAIN.md](../../DOMAIN.md). Overview: [API.md](../../API.md). Index: [../README.md](../README.md).

Resource names only: `events`, `event_teams`, `event_participants`, `invitations`. **Never** `/teams`, `/participants`, `/invitees`.

## Owned operationIds

| operationId | Method | Path |
|-------------|--------|------|
| `listEvents` | `GET` | `/api/v1/events` |
| `createEvent` | `POST` | `/api/v1/events` |
| `getEvent` | `GET` | `/api/v1/events/{id}` |
| `updateEvent` | `PATCH` | `/api/v1/events/{id}` |
| `deleteEvent` | `DELETE` | `/api/v1/events/{id}` |
| `listEventParticipants` | `GET` | `/api/v1/events/{event_id}/event_participants` |
| `listEventTeamParticipants` | `GET` | `/api/v1/events/{event_id}/event_teams/{event_team_id}/event_participants` |
| `joinOrSwitchEventParticipant` | `POST` | `/api/v1/events/{event_id}/event_participants` |
| `deleteEventParticipant` | `DELETE` | `/api/v1/event_participants/{id}` |
| `listEventInvitations` | `GET` | `/api/v1/events/{event_id}/invitations` |
| `createEventInvitations` | `POST` | `/api/v1/events/{event_id}/invitations` |

Teams rename: `listEventTeams` / `getEventTeam` / `updateEventTeam` → hub.

## Viewer CTAs (`current_user` on Event)

| Context | Flags | CTAs |
|---------|-------|------|
| author | participant, can_invite, author | edit, delete, invite, switch, leave |
| participant | participant, can_invite | invite, switch, leave |
| invited | invited | join |
| public stranger | all false | join |
| private stranger | — | **404** — no payload |

## Visibility / join

- Index = `visible_to` + upcoming only.
- Private / not viewable / not joinable → **404** (never 403 “request access”).
- Non-author update/delete when viewable → **403**; when not viewable → **404**.
- `price` / `latitude` / `longitude`: **numbers on write**, **strings on read**.

## Participants

- Body: `{ "event_participant": { "event_team_id": 123 } }`
- First join **201**, switch **200**. Countable full → **422**; bench stays joinable if event is.
- Leave: own `event_participants/{id}` only → **204**.
- After join/switch: refetch **team** roster only (`listEventTeamParticipants`).

## Invitations

- No decline/cancel/expire API — row exists until join or event destroy.
- Only participants (`can_invite`) may invite; else **403**.
- Empty/ineligible `user_ids` → **422** `"No users to invite"`.
- Nested `user` is **PublicUser**.
- Picker compose: accepted friendships − participants − invitations.

## Regenerate

```bash
bundle exec rake rswag:specs:swaggerize
bundle exec rake openapi:export
bundle exec rake mobile:export_events_docs
```
