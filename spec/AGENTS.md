# Spec Agent Guide

PR reviews: [.cursor/BUGBOT.md](.cursor/BUGBOT.md). Cursor Agent: [.cursor/rules/rspec.mdc](../.cursor/rules/rspec.mdc).

This app uses strict TDD with RSpec and Factory Bot.

## Scope

- Add or update specs only in `spec/models/` unless the user explicitly changes the testing policy.
- Do not add request specs, view specs, helper specs, system specs, feature specs, or display-only tests.
- Do not use YAML fixtures.
- Do not leave pending examples.

## Style

- Write specs around business behavior, not implementation details.
- Use factories from `spec/factories/`.
- Prefer explicit examples for validations, uniqueness, callbacks, and data side effects.
- Keep setup small and readable.
- Use traits for meaningful variants.

## TDD Flow

1. Capture the expected behavior in a failing model spec.
2. Implement the smallest model change that satisfies the behavior.
3. Refactor only if it makes the tested behavior clearer.

Do not run the test suite unless the user explicitly asks.
