# Frontend Policy

FlipFlapp uses a Rails-first frontend approach.

## Default Stack

- ERB templates
- Rails 8 view helpers and tags
- Tailwind CSS 4 utilities
- semantic HTML

Use this default unless the user asks for richer frontend behavior or the existing local pattern already uses Hotwire or Stimulus.

## Tailwind First

- Prefer utility classes over custom CSS.
- Keep layout simple and responsive.
- Avoid broad redesigns unless requested.
- Reuse nearby UI patterns before inventing new ones.
- Keep forms, buttons, links, and navigation consistent with the existing app.

## Rails-Native Views

- Prefer Rails form helpers and URL helpers.
- Keep business logic out of views.
- Use partials when reuse is real, not for every small fragment.
- Shared components belong under `app/views/**/components/`.

## Hotwire And Stimulus

Use Hotwire, Turbo, or Stimulus when:

- the user asks for interaction;
- the feature needs progressive enhancement;
- the current page already has the relevant pattern;
- static ERB would create awkward duplication or poor UX.

Do not add JavaScript dependencies unless explicitly requested.

## Copy And Translation

- Technical docs are written in English.
- User-facing app copy should be prepared for model-scoped translations.
- If translation scope is unclear, ask before adding broad locale files.
