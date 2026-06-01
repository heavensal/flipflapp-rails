# Bugbot — specs

Also read: [spec/AGENTS.md](../AGENTS.md), [docs/TESTING.md](../../docs/TESTING.md).

## Blocking checks

- New `spec/requests/**`, `spec/views/**`, `spec/helpers/**`, `spec/system/**` files.
- `pending` examples without issue reference.
- YAML fixtures under `spec/fixtures/`.
- Specs that only assert HTTP status or HTML (display-only).

## Required patterns

- Specs live in `spec/models/` for business behavior.
- Factory Bot (`create`, `build`); traits for variants (`:unconfirmed` on users).
- Examples name the **rule** (validation, uniqueness, callback side effect).

## Review focus

- Factories that bypass validations critical to the rule under test.
- Missing assertions on notification counts when callbacks create notifications.
- Tests that hit production external services (Cloudinary, etc.) without stubs.
