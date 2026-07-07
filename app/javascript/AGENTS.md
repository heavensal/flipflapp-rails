# JavaScript

Frontend policy: [docs/FRONTEND.md](../../docs/FRONTEND.md). PR: [.cursor/BUGBOT.md](../../.cursor/BUGBOT.md).

**Ask before creating a new Stimulus controller.**

```
app/javascript/controllers/<feature>/<name>_controller.js
```

Register in `index.js` with namespace: `form--image-preview` → `application.register("form--image-preview", ...)`.

Keep controllers small; `data-*` attributes; no new JS deps unless asked.

Cursor: [.cursor/rules/javascript.mdc](../../.cursor/rules/javascript.mdc)
