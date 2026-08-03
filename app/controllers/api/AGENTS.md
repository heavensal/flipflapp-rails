# API controllers

Layer under `app/controllers/api/`.

- Inherit from `Api::V1::BaseController` (`ActionController::API`), not `ApplicationController`
- Mirror web resource names exactly (`event_teams`, `event_participants`, `friendships`, …) — Convention over Configuration
- Thin: auth, strong params, model domain methods, Alba serializers
- Domain rules stay in models; never duplicate visibility / capacity / invite logic
- When a feature touches `/api/v1`, update API + request specs + OpenAPI **and** the affected LLM-ready mobile bundle (`docs/mobile/auth/`, `docs/mobile/users/`, `docs/mobile/events/`, `docs/mobile/notifications/`, `docs/mobile/device_tokens/`, or `docs/api/v1/`) in the same change — required, not optional
- Docs: [docs/API.md](../../../docs/API.md) Feature co-evolution, [docs/TESTING.md](../../../docs/TESTING.md) Step 7, [docs/DOMAIN.md](../../../docs/DOMAIN.md), [docs/mobile/README.md](../../../docs/mobile/README.md)
