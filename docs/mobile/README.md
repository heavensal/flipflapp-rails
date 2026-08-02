# FlipFlapp mobile API docs (LLM-ready)

Prefer these handoffs over Swagger UI when implementing iOS/Android. Each domain folder has `openapi.json` (full v1 dump — filter by `operationId`) plus companions.

| Bundle | Path | Owns |
|--------|------|------|
| Auth | [`auth/`](auth/) | register, sign-in/out, confirm, password reset |
| Users / profile | [`users/`](users/) | `me`, `users/{id}`, avatar, email reconfirm |
| Events | [`events/`](events/) | Events CRUD, participants join/leave, invitations |
| Notifications | [`notifications/`](notifications/) | inbox list/read/delete |
| Device tokens | [`device_tokens/`](device_tokens/) | FCM register/unregister |
| EventTeams + Friendships | [`../api/v1/`](../api/v1/) | team rename, friendships, invite-picker compose |

**Feature gate:** any `/api/v1` change must update the matching bundle in the same change — [TESTING.md](../TESTING.md) Step 7, [API.md](../API.md) Feature co-evolution.

Regenerate (after `rswag:specs:swaggerize` + `openapi:export`):

```bash
bundle exec rake mobile:export_auth_docs
bundle exec rake mobile:export_users_docs
bundle exec rake mobile:export_events_docs
bundle exec rake mobile:export_notifications_docs
bundle exec rake mobile:export_device_tokens_docs
```
