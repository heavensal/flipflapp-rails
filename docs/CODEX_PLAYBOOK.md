# Codex Playbook

Operational guide for Codex CLI, app, IDE, and cloud tasks. Durable policy lives in [AGENTS.md](../AGENTS.md); product truth lives in [PROJECT.md](PROJECT.md) and [DOMAIN.md](DOMAIN.md).

## Default task protocol

For every non-trivial task, Codex follows this sequence:

1. **Orient** — read `AGENTS.md`, `PROJECT.md`, the relevant `DOMAIN.md` section, and nested instructions for the target layer.
2. **Inspect** — read routes, schema, nearby code, factories, and existing specs. Do not infer current behavior from filenames alone.
3. **Classify** — identify whether the task changes domain behavior, HTTP wiring, UI only, schema, infrastructure, or documentation.
4. **Bound** — state what is in scope, what is deliberately out of scope, ambiguities, and whether approval is required.
5. **Choose Rails-native mechanics** — prefer installed framework APIs. Identify any appropriate generator or command before hand-writing boilerplate.
6. **Request permission** — commands, generators, migrations, new dependencies, new Stimulus controllers, service objects, commits, pushes, and deploys require explicit approval.
7. **Build in dependency order** — domain/spec first, then model, HTTP, view, and JavaScript only if needed.
8. **Verify proportionally** — inspect the diff and static consistency always; run requested tests, lint, security scans, or browser checks only with permission.
9. **Report** — summarize behavior delivered, files changed, verification performed/not performed, and remaining decisions.

## Required reading by task

| Task | Read before editing |
|------|---------------------|
| Any feature | `PROJECT.md`, relevant `DOMAIN.md`, `TESTING.md` |
| Model/business rule | `app/models/AGENTS.md`, schema, model, factory, model spec |
| Controller/route | `app/controllers/AGENTS.md`, `config/routes.rb`, model authorization API, request specs |
| Background job | `app/jobs/AGENTS.md`, enqueue caller, idempotency/cancellation behavior, model specs |
| View/UI | `app/views/AGENTS.md`, `FRONTEND.md`, `I18N.md`, nearest components |
| JavaScript | `app/javascript/AGENTS.md`, existing controllers and registration |
| Database | `db/schema.rb`, associations/validations/indexes, migration policy |
| Codex/OpenAI tooling | `openaiDeveloperDocs` MCP, exact current official page |

## Permission matrix

| Action | Codex may do immediately | Explicit approval required |
|--------|--------------------------|----------------------------|
| Read/search files, inspect git diff/status | Yes | No |
| Edit requested in-scope source/docs/specs | Yes | No |
| Propose a command or generator | Yes | No |
| Run any shell command, test, lint, generator, setup task | No | Yes |
| Propose schema/index changes | Yes | No |
| Create a migration file or change `db/schema.rb` | No | Yes, after migration plan validation |
| Run `db:migrate`, `db:prepare`, reset, seed, or schema load | No | Yes, separately |
| Add gem/npm dependency or Stimulus controller | No | Yes |
| Introduce a service object or new architectural layer | No | Yes |
| Commit, push, open PR, deploy | No | Yes |

Approval for one action does not imply approval for adjacent actions. Approval to create a migration does not approve running it; approval to run specs does not approve the full suite or database preparation.

## Framework-first rule

Before manually creating Rails/framework boilerplate:

1. Check the installed framework and version (`Gemfile`, lockfiles, existing configuration).
2. Identify the narrowest native generator or setup command.
3. Present the exact command, files it should create/change, and unwanted output that will be removed.
4. Wait for approval.
5. Run only the approved command, review every generated file, and adapt it to project conventions.

Never generate a model, scaffold, resource, or migration merely for convenience. Prefer focused generators, and never let generated code define domain behavior.

## Feature prompt

```text
Build [feature] using AGENTS.md and docs/TESTING.md.
Read docs/PROJECT.md and the relevant docs/DOMAIN.md section first.
Inspect current routes, schema, implementation, factories, and specs.
Flag ambiguities and approval gates before editing.
If framework boilerplate is needed, propose the Rails-native generator first.
Propose migrations for approval before creating files; never run them implicitly.
Write model specs first, then the smallest conventional Rails implementation.
Do not run commands unless I approve the exact command.
```

## UI prompt

```text
Update [screen] under docs/FRONTEND.md and app/views/AGENTS.md.
Reuse the nearest existing ERB component and Tailwind pattern.
Use only Tailwind CSS utilities and I18n keys; no custom CSS or inline styles.
Keep domain logic and authorization out of the view.
Ask before adding JavaScript, a Stimulus controller, or a dependency.
```

## Migration prompt (after plan approval)

```text
Create only the approved migration for [change].
Include matching database constraints/indexes, model validations, factories,
and model specs. Do not run db:migrate or edit schema.rb manually.
```

## Review prompt

```text
Review this change against AGENTS.md, PROJECT.md, DOMAIN.md, and nested instructions.
Prioritize correctness, authorization, data integrity, regressions, missing specs,
N+1 queries, transaction boundaries, MVP scope, and Tailwind/I18n compliance.
List actionable findings with file references. Do not edit or run commands.
```

## Completion report

Codex must end with:

- the user-visible or domain outcome;
- the important implementation choices;
- files or layers changed;
- tests/checks run and their results, or an explicit note that none were run;
- migrations, commands, dependencies, or decisions still awaiting approval;
- any known gap against the MVP quality gates in [PROJECT.md](PROJECT.md).
