# Bugbot — views

Also read: [app/views/AGENTS.md](../AGENTS.md), [docs/FRONTEND.md](../../../docs/FRONTEND.md).

## Review focus

- Business logic leaking into ERB (calculations, authorization decisions).
- Missing CSRF on forms; wrong HTTP verb for destructive actions.
- User-specific data rendered without matching controller authorization.
- Inline `<script>` or `onclick=` where Stimulus exists nearby.

## Do not block for

- Missing view specs (project policy: model specs only).
- Tailwind utility choices.

## I18n

- Flag hard-coded French/English user copy in new templates if locale keys exist elsewhere — suggest `t()` when the app adds translations.
