# JavaScript Agent Guide

PR reviews: [.cursor/BUGBOT.md](.cursor/BUGBOT.md). Cursor Agent: [.cursor/rules/javascript.mdc](../../.cursor/rules/javascript.mdc).

Rails-native HTML and Tailwind CSS are the default. JavaScript should be added only when the requested behavior needs it.

## Stimulus

- Put controllers in `app/javascript/controllers/`.
- Register new controllers in `app/javascript/controllers/index.js`.
- Keep controllers small and tied to one interaction.
- Prefer data attributes over querying fragile CSS selectors.
- Do not add new JavaScript dependencies unless explicitly requested.

## Turbo

- Use Turbo when the requested behavior benefits from Rails-native progressive enhancement.
- Keep server-rendered HTML as the source of truth.

Do not run build commands unless the user explicitly asks.
