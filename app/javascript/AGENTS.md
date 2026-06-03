# JavaScript Agent Guide

PR reviews: [.cursor/BUGBOT.md](.cursor/BUGBOT.md). Cursor Agent: [.cursor/rules/javascript.mdc](../../.cursor/rules/javascript.mdc).

Rails-native HTML and Tailwind CSS are the default. JavaScript should be added only when the requested behavior needs it.

## Stimulus

### Permission Required

**Do NOT create a new Stimulus controller without explicit user permission.** If a feature requires a Stimulus controller, explain the need and ask the user to approve its creation before writing any code.

### Folder Structure

Organize controllers by feature domain using subfolders:

```
app/javascript/controllers/
├── application.js
├── index.js
├── form/
│   ├── image_preview_controller.js
│   └── registration_controller.js
├── maps/
│   └── autocomplete_controller.js
└── navbar_controller.js
```

Pattern: `<feature>/<specificity>_controller.js`

- Group related controllers under a feature folder (e.g. `form/`, `maps/`).
- Register namespaced controllers with double-dash separator: `form--image-preview`, `form--registration`, `maps--autocomplete`.
- In `index.js`, import from the subfolder and register with the namespace: `application.register("form--image-preview", FormImagePreviewController)`.

### General Rules

- Register new controllers in `app/javascript/controllers/index.js`.
- Keep controllers small and tied to one interaction.
- Prefer `data-*` attributes over querying fragile CSS selectors.
- Do not add new JavaScript dependencies unless explicitly requested.

## Turbo

- Use Turbo when the requested behavior benefits from Rails-native progressive enhancement.
- Keep server-rendered HTML as the source of truth.

Do not run build commands unless the user explicitly asks.
