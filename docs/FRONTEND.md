# Frontend

Rails-first UI: ERB, Tailwind CSS 4, semantic HTML. Copy: [I18N.md](I18N.md). Cross-layer style: [RAILS_STYLEGUIDE.md](RAILS_STYLEGUIDE.md).

## Stack

- **ERB** + Rails 8 view helpers — default for all UI
- **Tailwind CSS 4** — utilities from existing components; no new visual language
- **Hotwire / Stimulus** — only when static ERB is not enough
- **npm** only (`package-lock.json`) — see [DEVELOPMENT.md](DEVELOPMENT.md)

## When to use JavaScript

Use Hotwire, Turbo, or Stimulus when:

- the user asks for interaction;
- static ERB would be awkward or duplicated;
- the page already uses the same pattern nearby.

**Ask before creating a new Stimulus controller.** Folder structure and registration: [app/javascript/AGENTS.md](../app/javascript/AGENTS.md).

Do not add npm dependencies unless explicitly requested.

## Views

- No business logic in templates (no authorization decisions, no domain calculations).
- Rails form helpers and URL helpers.
- Files under **150 lines** — split partials when growing.

## View components

Path: `app/views/<feature>/components/_<name>.html.erb`

- **Lists** — one partial per item (e.g. `events/components/_one_event_card.html.erb`).
- **Extract** when the same ~**10 lines** of markup repeat (or will on the next similar screen).
- **Do not** extract one-off fragments; copy the nearest existing component first.

Examples in the repo:

- `app/views/events/components/_one_event_card.html.erb`
- `app/views/notifications/components/_one_notification.html.erb`
- `app/views/events/components/_show_event_info_card.html.erb`

## Corrections log

Add a row when an agent repeats a frontend mistake.

| Date | Don't | Do instead |
|------|-------|------------|
| | | |
