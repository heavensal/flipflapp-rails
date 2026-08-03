# Events mobile docs moved

The LLM-ready Events contract now lives at **[`docs/mobile/events/`](../../../docs/mobile/events/)**.

Use that directory (`CLIENT_CONTRACT.md`, `client.json`, `errors.json`, `flows.json`, `openapi.json`) instead of this folder.

```bash
bundle exec rake mobile:export_events_docs
```

Parent OpenAPI remains [`../openapi.json`](../openapi.json) after `openapi:export`.
