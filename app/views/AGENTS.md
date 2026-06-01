# View Layer Agent Guide

PR reviews: [.cursor/BUGBOT.md](.cursor/BUGBOT.md). Cursor Agent: [.cursor/rules/views.mdc](../../.cursor/rules/views.mdc).

Views should stay simple, semantic, and Rails-native.

## Defaults

- Use ERB and Rails 8 view helpers first.
- Use Tailwind CSS 4 utilities for styling.
- Keep markup readable and avoid unnecessary partial extraction.
- Extract shared partials under `app/views/**/components/` only when reuse is real.
- Keep user-facing copy ready for translation through locale files.

## Avoid

- Do not add inline JavaScript for behavior that belongs in Stimulus.
- Do not introduce frontend frameworks.
- Do not add display tests unless explicitly requested.
- Do not add broad UI rewrites unless the user asks for frontend improvement.

## Hotwire And Stimulus

Use Hotwire, Turbo, or Stimulus only when:

- the user asks for interactive behavior;
- a simple Rails view cannot reasonably handle the interaction;
- the existing code already uses that controller or pattern nearby.
