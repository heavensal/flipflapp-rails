# FlipFlapp mobile Notifications contract (`/api/v1`)

LLM-ready inbox handoff. Prefer this directory over Swagger UI for notifications screens.

| Bundle | Path |
|--------|------|
| **Notifications (this)** | [`docs/mobile/notifications/`](./) |
| Device tokens (push registration) | [`docs/mobile/device_tokens/`](../device_tokens/) |
| Friendships (`friendship_requested`) | [`docs/api/v1/`](../../api/v1/) |
| Events (producers) | [`docs/mobile/events/`](../events/) |

Domain: [DOMAIN.md](../../DOMAIN.md) → Notification. Index: [../README.md](../README.md).

Resource name: `notifications` only — never `/alerts` or `/inbox`.

## OperationIds

| operationId | Method | Path | Success |
|-------------|--------|------|---------|
| `listNotifications` | `GET` | `/api/v1/notifications` | `200` array ≤20 |
| `readNotification` | `PATCH` | `/api/v1/notifications/{id}/read` | `200` Notification |
| `readAllNotifications` | `PATCH` | `/api/v1/notifications/read_all` | `204` empty |
| `deleteNotification` | `DELETE` | `/api/v1/notifications/{id}` | `204` empty |

Bearer required. Never issues JWT.

## Inbox rules

- Scope: `inbox` = all kinds **except** `friendship_requested`.
- Order: newest first; **max 20**.
- Looking up a `friendship_requested` id → **404**.
- `canceled` may have `notifiable` null — still readable/deletable.

## friendship_requested

| Channel | Behavior |
|---------|----------|
| Inbox list | **Excluded** |
| Friends badge | `listFriendships.received` |
| Push | May still fire — open friendships `received`, **not** this inbox |

## Example Notification (inbox)

```json
{
  "id": 10,
  "kind": "invited",
  "read": false,
  "payload": { "sender": "Ada" },
  "created_at": "2026-08-02T18:00:00.000Z",
  "notifiable_type": "Event",
  "notifiable_id": 3
}
```

## Regenerate

```bash
bundle exec rake rswag:specs:swaggerize
bundle exec rake openapi:export
bundle exec rake mobile:export_notifications_docs
```
