# Testing Policy

FlipFlapp uses strict TDD with RSpec and Factory Bot.

## Non-Negotiable Rules

- Write or update model specs before changing business behavior.
- Keep specs in `spec/models/` unless explicitly instructed otherwise.
- Do not add request specs, view specs, helper specs, system specs, or display-only tests.
- Use Factory Bot. Do not add YAML fixtures.
- Do not leave pending examples.
- Do not run test commands unless explicitly asked.

## What To Test

Model specs should cover:

- validations
- uniqueness rules
- associations that enforce behavior
- callbacks that change data
- creation and cleanup of notifications
- friendship rules
- event participation rules
- team composition and lifecycle rules
- data integrity after create, update, and destroy

## What Not To Test By Default

Do not add tests for:

- HTML layout
- CSS classes
- view rendering
- request routing
- controller response codes
- helper formatting
- JavaScript display behavior

These can be added only if the user explicitly changes the policy for a task.

## TDD Conversation Pattern

When a feature is underspecified, ask for the tests first:

- What should be valid?
- What should be invalid?
- Which records should change?
- Which records should remain unchanged?
- Which notifications should be created or removed?
- Which edge case matters most?

After the user confirms behavior, implement the smallest model change that satisfies the spec.
