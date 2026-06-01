# Codex Playbook

Use this file for high-signal prompts and workflows. It is intentionally not loaded automatically by Codex; reference it when needed.

## Best Prompt Pattern

Ask for the outcome, the allowed scope, and the validation method.

Example:

```text
Implement the event cancellation rule with strict TDD.
Only edit models and model specs.
Do not create migrations.
Ask me for missing business rules before coding.
Do not run commands unless I ask.
```

## Feature Prompt

```text
Build [feature] using strict TDD.
Start by proposing the model specs that should define the behavior.
Do not create migrations unless I explicitly approve them.
Prefer Rails-native ERB and Tailwind if views are needed.
Do not run commands.
```

## Review Prompt

```text
Review this change as a Rails code reviewer.
Focus on bugs, broken business rules, missing model specs, unsafe migrations, security issues, and deploy risk.
List findings first with file and line references.
Do not rewrite code unless I ask.
```

## Frontend Prompt

```text
Update this view using Rails-native ERB and Tailwind CSS 4.
Avoid Stimulus and Hotwire unless the interaction requires them.
Keep copy translation-ready.
Do not add display tests.
```

## Migration Prompt

```text
Create the migration/model for [domain concept].
Use strict TDD with model specs.
Include model validations and database indexes where appropriate.
Do not run the migration unless I ask.
```

## CI Prompt

```text
Inspect the failing CI context and propose the smallest fix.
Do not push or modify deployment configuration unless the failure requires it.
Ask before running any command locally.
```

## Documentation Prompt

```text
Update the project documentation in English.
Keep AGENTS.md short and move detailed guidance into docs files.
Optimize for fewer tokens loaded by default.
```
