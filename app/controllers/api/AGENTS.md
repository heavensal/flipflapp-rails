# API controllers

Layer under `app/controllers/api/`.

- Inherit from `Api::V1::BaseController` (`ActionController::API`), not `ApplicationController`
- Mirror web resource names exactly (`event_teams`, `event_participants`, `friendships`, …) — Convention over Configuration
- Thin: auth, strong params, model domain methods, Alba serializers
- Domain rules stay in models; never duplicate visibility / capacity / invite logic
- When a feature changes the mobile HTTP contract, update API + OpenAPI (`spec/requests/api/v1`, rswag) in the same change
- Docs: [docs/API.md](../../../docs/API.md), [docs/TESTING.md](../../../docs/TESTING.md), [docs/DOMAIN.md](../../../docs/DOMAIN.md)
