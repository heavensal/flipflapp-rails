# FlipFlapp mobile Events contract bundle

Exportable handoff for iOS/Android (and LLM agents). No Rails repo required.

## Files

| File | Role |
|------|------|
| [`../openapi.json`](../openapi.json) | Full OpenAPI 3.0.1 contract (`/api/v1`) |
| [`../swagger.yaml`](../swagger.yaml) | Same contract in YAML (rswag source artifact) |
| [`events_companion.json`](events_companion.json) | Events intents, flows, viewer CTAs, client rules |

## How to use

1. Load `openapi.json` for paths, schemas, `operationId`s, request/response examples, and status codes.
2. Load `events_companion.json` for “what next?”, invite-picker composition, offline/timeout rules, and `current_user` → CTA mapping.
3. Auth: send `Authorization: Bearer <jwt>` on every Events operation. Do not re-implement Auth from Events docs alone — use Auth ops in the same OpenAPI file (`signIn`, etc.).

## Regenerate (from the Rails repo)

```bash
bundle exec rake rswag:specs:swaggerize
bundle exec rake openapi:export
```

## Events operationIds

`listEvents`, `createEvent`, `getEvent`, `updateEvent`, `deleteEvent`, `listEventTeams`, `getEventTeam`, `updateEventTeam`, `listEventParticipants`, `listEventTeamParticipants`, `joinOrSwitchEventParticipant`, `deleteEventParticipant`, `listEventInvitations`, `createEventInvitations`.

Resource path names stay Convention over Configuration: `events`, `event_teams`, `event_participants`, `invitations` — no aliases.
