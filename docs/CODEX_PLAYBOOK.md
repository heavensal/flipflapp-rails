# Codex Playbook

Copy-paste prompts for Codex CLI / Cloud. **Policies and workflow:** [AGENTS.md](../AGENTS.md) and [TESTING.md](TESTING.md).

## Feature (default)

```text
Build [feature] using the workflow in docs/TESTING.md.
Read docs/DOMAIN.md first. Flag ambiguities before coding.
Propose migrations for my approval before creating db/migrate/ files.
Write failing spec/models/ specs, then implement.
Match docs/RAILS_STYLEGUIDE.md. Do not run commands unless I ask.
```

## Model-only change

```text
Implement [rule] with strict TDD.
Only edit app/models/ and spec/models/.
Do not create migrations unless I approve.
Do not run commands.
```

## View change

```text
Update the view using docs/FRONTEND.md (ERB, Tailwind, components).
Copy an existing component in app/views/<feature>/components/.
I18n keys for user-facing copy. Ask before new Stimulus controller.
```

## Migration (after approval)

```text
Create the migration for [change].
Include model validations, indexes, and spec/models/ coverage.
Do not run db:migrate unless I ask.
```

## Review

```text
Review as a Rails reviewer. Check DOMAIN.md and spec/models/ coverage.
List findings with file references. Do not rewrite unless I ask.
```

## CI fix

```text
Propose the smallest fix for the failing CI check.
Do not push or change deploy config unless required. Ask before running commands.
```
