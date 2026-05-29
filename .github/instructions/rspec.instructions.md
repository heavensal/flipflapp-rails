---
applyTo: "spec/**/*"
---

# RSpec — modèles et data uniquement

- `spec/models/` only: validations, uniqueness, CRUD callbacks, data integrity.
- Factory Bot (`create`, `build`) — no YAML fixtures.
- Do not add request, view, or system specs for CI/deploy gates.
- Assert `valid?` / `errors` and record counts (`change { Model.count }`).
