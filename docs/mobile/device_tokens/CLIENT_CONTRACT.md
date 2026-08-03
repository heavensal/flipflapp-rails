# FlipFlapp mobile DeviceTokens contract (`/api/v1`)

LLM-ready FCM registration handoff. Prefer this directory for push token lifecycle.

| Bundle | Path |
|--------|------|
| **Device tokens (this)** | [`docs/mobile/device_tokens/`](./) |
| Auth (JWT) | [`docs/mobile/auth/`](../auth/) |
| Notifications inbox | [`docs/mobile/notifications/`](../notifications/) |

Domain: [DOMAIN.md](../../DOMAIN.md) → DeviceToken. Index: [../README.md](../README.md).

Singular resource: `/api/v1/device_token` — **never** invent `/push_tokens` or `/device_tokens`.

## OperationIds

| operationId | Method | Path | Success |
|-------------|--------|------|---------|
| `registerDeviceToken` | `POST` | `/api/v1/device_token` | **200** empty body |
| `unregisterDeviceToken` | `DELETE` | `/api/v1/device_token` | **204** empty (idempotent) |

## Body

Register:

```json
{ "device_token": { "token": "fcm-abc", "platform": "android" } }
```

`platform` optional → defaults to `android`. Allowed: `android` \| `ios`. Reject `web` → 422.

Unregister:

```json
{ "device_token": { "token": "fcm-abc" } }
```

## Traps

- Register is **200**, not 201.
- Same token reassigned to the current user on register.
- Unregister missing token still **204**.
- Register after JWT; unregister **before** `signOut` while Bearer is valid.
- Android FCM implemented; APNs/iOS delivery may still be pending (table supports `ios`).

## Regenerate

```bash
bundle exec rake rswag:specs:swaggerize
bundle exec rake openapi:export
bundle exec rake mobile:export_device_tokens_docs
```
