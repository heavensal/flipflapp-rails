# Model Layer Agent Guide

PR reviews: [.cursor/BUGBOT.md](.cursor/BUGBOT.md) (Bugbot). Cursor Agent: [.cursor/rules/models.mdc](../../.cursor/rules/models.mdc).

This directory owns domain rules, validations, associations, callbacks, and database side effects.

## Required Workflow

- Use strict TDD for every model behavior change.
- Start with or update a spec in `spec/models/`.
- Encode the business rule in the spec before changing implementation.
- If the rule is unclear, ask for expected examples and edge cases before coding.

## Model Rules

- Prefer simple Active Record validations, associations, scopes, and callbacks.
- Keep domain behavior close to the model that owns the data.
- Avoid service objects or new abstraction layers unless explicitly requested.
- Keep callbacks narrow, deterministic, and covered by model specs when they change data.
- Use database constraints only when the user explicitly allowed the migration or schema change.

## Migrations

- Do not generate or edit migrations from this directory unless the user explicitly requested a migration, model, table, column, index, or schema change.
- If a validation requires a matching database index or constraint, explain the gap and ask before creating it.

## Specs To Update

Use `spec/models/` for:

- validations
- uniqueness rules
- associations that enforce behavior
- callbacks that create, update, or destroy data
- notification side effects
- friendship and participation rules
- event/team lifecycle rules
