# Phase 6 OpenSpec Project Template

Date: 2026-08-03

## Status

Phase 6 is **PASS**. The framework now provides a project-local bootstrap at
`templates\project` and concise artifact guidance at `templates\openspec`.
Neither location contains product-specific facts, active changes, a global
OpenCode configuration change, a custom OpenSpec schema, or a custom command.

## Delivered Bootstrap

| Asset | Purpose |
|---|---|
| `templates\project\PRODUCT.md` | Stable product intent, users, constraints, and non-goals. |
| `templates\project\DESIGN.md` | Optional enduring architecture and operational decisions. |
| `templates\project\openspec\config.yaml` | CLI-generated default `spec-driven` OpenSpec configuration. |
| `templates\project\.opencode\commands\opsx-*.md` | The five CLI-generated OpenCode core commands: apply, archive, explore, propose, and sync. |
| `templates\openspec\` | Concise references for proposal, delta spec, design, tasks, research, verification, and release records. |

`templates\openspec\README.md` defines the minimal default artifact graph for
a small change: proposal, delta spec, concise design, and tasks. Research,
verification, and release records are adjacent evidence artifacts, not a second
schema or workflow engine.

## Evidence Path

The Phase 6 claim is that a participating project can begin with project-local
facts and the standard OpenSpec workflow, receive only OpenSpec OpenCode
commands, and validate a complete change strictly. The relevant failure modes
are a custom schema hidden in the template, additional framework commands,
invalid spec grammar, or a claim that a placeholder fixture validates when it
does not.

| Claim | Evidence | Result |
|---|---|---|
| Standard project structure and strict validation syntax | Context7 documentation for `/fission-ai/openspec/v1.5.0`; CLI help for `init` and `validate` | Established. The default schema is `spec-driven`; `validate <item> --strict --no-interactive` is supported. |
| OpenCode integration produces only OpenSpec commands | `npx --yes @fission-ai/openspec@1.5.0 init .\templates\project --tools opencode --profile core` | Established. The CLI created five `.opencode\commands\opsx-*.md` files and no skills. |
| A complete fixture validates strictly | `scripts\Test-OpenSpecProjectTemplate.ps1` | Established. `add-status-endpoint` reports `Change 'add-status-endpoint' is valid`. |
| Template command surface cannot drift locally | `scripts\Test-FrameworkSkeleton.ps1` | Established. It requires exactly the five generated OpenSpec command files and rejects additional project-template commands. |

## Authoring Rules

The OpenSpec CLI's `instructions` output is authoritative for an active
artifact's structure and resolved path. The local reference templates are
guidance only and deliberately retain the default `spec-driven` schema.

For an external dependency, framework, SDK, API, CLI, or service decision,
record the official Context7 result and source provenance in `research.md`.
Use the evidence table fields from `PLAN.md`: claim, source/tool, version/path,
evidence, and status. Record local source inspection separately when relevant.

Each requirement scenario is a candidate test or direct verification check. For
bugs, data, security, public API, and regression risks, add or update a focused
check before implementation when practical. If automated testing is not
proportionate, record the direct check and its remaining uncertainty in
`verification.md`.

Pause for approval on the material deviations listed in `PLAN.md` section 12.3:
unapproved dependencies or services; public contract, data, migration, auth,
privacy, security, UI, scope, cost, delivery, release, or rollback changes; and
destructive or irreversible actions. Do not pause routine inspection, focused
tests, local refactors, or repairs inside the approved plan.

## Verification

Run from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenSpecProjectTemplate.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-FrameworkSkeleton.ps1
```

The first command requires registry access to retrieve the exact pinned CLI if
it is not already available in the npm cache. It performs no global OpenCode or
OpenChamber write. The second command is local and checks layout, command
surface, and repository safety only.

## Fresh Project End-To-End Validation

On 2026-08-03, `templates\project` was copied without modification to the
fresh temporary directory
`C:\Users\quang\AppData\Local\Temp\opencode\phase6-bootstrap-e2e`.
The project initially reported no active changes. The generated `opsx-propose`
and `opsx-apply` command sources, project `PRODUCT.md`, and default
`openspec\config.yaml` were inspected in that copied project.

The following flow then passed:

1. `npx --yes @fission-ai/openspec@1.5.0 new change add-status-endpoint`
   created the repo-local `spec-driven` change.
2. The artifact order returned by `openspec status --change ... --json` was
   followed: proposal, design and delta spec, then tasks.
3. The global `openspec` binary on `PATH` reported `1.6.0`; its `status` and
   `instructions apply` commands recognized all four artifacts as complete and
   exposed their concrete context paths.
4. `openspec validate add-status-endpoint --strict --no-interactive` reported
   `Change 'add-status-endpoint' is valid`.

This establishes a complete planning-to-apply-ready flow in a newly copied
project. It does not establish project implementation, application tests,
release, successful archive, or OpenCode UI command-discovery behavior. The
fixture tasks intentionally remain incomplete because the temporary project has
no application implementation to truthfully complete.

## Setup Gaps Found

| Gap | Evidence | Required handling |
|---|---|---|
| Generated command execution is not version-pinned | Commands generated by `@fission-ai/openspec@1.5.0` call bare `openspec`. The fresh-project environment resolved that command to `1.6.0`; the tested flow was compatible, but this is not a version guarantee. | Install the reviewed `1.5.0` CLI on `PATH` and check `openspec --version` before slash-command use. `npx` remains appropriate for explicitly pinned one-off validation. |
| `core` lacks the continuation surface named by generated apply guidance | `opsx-apply.md` historically instructed `/opsx-continue` for a blocked change. A fresh `blocked-apply` change returned `state: "blocked"` and named the unavailable `openspec-continue-change` skill. The core bootstrap contains only apply, archive, explore, propose, and sync. | The generated prompt now documents concrete installed-CLI recovery: read `openspec status --change <name> --json`, iterate `openspec instructions <artifact-id> --change <name> --json` for each missing artifact, populate the resolved `contextFiles` path, and re-run apply. Treat this as an upstream core-profile limitation; do not add a custom continuation command. |
| Generated archive is not PowerShell-idempotent and is not gated by release, approval, or pre-release validation | In the fresh Windows project, its `openspec\changes\archive` directory already existed. The generated `/opsx-archive` `mkdir -p` step emitted PowerShell's `ResourceExists` error. The default prompt also lacked any release, user-approval, or strict pre-release validation gate, so an unapproved or unverified change could archive. | The generated prompt now uses `openspec archive <change-name>` on Windows, resolves `release.md` and `verification.md` paths from the status JSON, and aborts the archive when a public-boundary change has no recorded release, when explicit user approval is missing, or when strict OpenSpec validation has not been re-run since the last external action. Treat this as the framework's release/approval/pre-release validation gate. |
| Reference templates are not self-contained in the copied project | The fresh project intentionally contained no `templates\openspec\` directory. Its valid source of truth is the CLI `instructions` response. | Keep the framework checkout available when reference guidance is useful, or use the live CLI instructions. This is not a blocker for the default artifact graph. |
| Slash-command discovery needs an OpenCode reload | `openspec init` reports that the IDE must restart for slash commands to take effect; the copied bootstrap does not itself trigger a reload. | Restart or reload OpenCode after copying the bootstrap. This validation did not automate a UI restart. |

## Automated Bootstrap Preflight

`templates\project\Test-OpenSpecBootstrapPreflight.ps1` is copied with every
bootstrap. It verifies that `openspec` is an application command on `PATH`,
executes `openspec --version`, and fails unless it exactly matches the reviewed
`1.5.0` version. It also requires the default configuration and all five
generated core command files.

The preflight parses each generated command source and emits deduplicated,
file-and-line-specific warnings for unavailable `/opsx-*` command dependencies,
unavailable project-local `openspec-*` skills, and the Windows-incompatible
`mkdir -p` archive step. Warnings leave the preflight successful because they
describe upstream generated-command limitations with documented workarounds;
CLI absence, mismatch, or missing bootstrap files fails the check.

The Windows pull-request workflow installs the exact
`@fission-ai/openspec@1.5.0` package, asserts `openspec --version`, copies the
bootstrap to a fresh runner-temporary directory, and runs the copied preflight.
This keeps the CLI and copy boundary under CI without adding a custom OpenSpec
command or schema.

`scripts\Test-FrameworkSkeleton.ps1` also parses every top-level workflow job
under `jobs:` in every `.github\workflows\*.yml` or `*.yaml` source and rejects
a missing or non-`windows-latest` runner. This makes the Windows-only framework
boundary an automated source gate, including for future CI jobs and workflows.

`fixtures\phase-6\ci-windows-only\` and
`scripts\Test-CiWindowsOnlyRegression.ps1` exercise the same guard against four
invalid job forms: `ubuntu-latest`, missing `runs-on`, a matrix runner, and a
reusable workflow job. Two valid fixtures cover a single `windows-latest` job
and a dependent multi-job `windows-latest` workflow. A third valid fixture uses
`runs-on: ${{ matrix.os }}` with a literal matrix that contains only
`windows-latest`. These prevent false positives while unknown or mixed matrices
remain rejected. A fourth valid fixture allows `matrix.include` only when every
include item explicitly uses `windows-latest`; non-Windows or unverified include
items remain rejected. The Windows pull-request workflow runs this regression
suite before the framework safety gate.

## Framework Release And Approval Gates

The generated `/opsx-archive` prompt now enforces the framework release,
approval, and pre-release validation gate. The gate resolves the
`release.md` and `verification.md` paths from the status JSON's `artifactPaths`
map, refuses to archive a public API, schema, data lifecycle, migration, auth,
payment, security, or release boundary change without a recorded release, and
re-runs strict OpenSpec validation when an external action has been recorded.
The bootstrap does not add a custom archive command; it relies on the installed
CLI and the generated prompt's gate so an unapproved or unverified change
cannot archive. The archive prompt steps are titled "Enforce framework release
and approval gates before archive" and require explicit user approval.

## Limits

- This phase does not install OpenSpec globally or modify an existing project.
- The templates do not prove a project's implementation, package, deployment,
  or release gates; those are recorded per change.
- The generated `/opsx-archive` prompt now enforces a release, approval, and
  pre-release validation gate, but the gate still resolves paths from the
  status JSON. A project that hand-crafts `release.md` or `verification.md`
  paths outside the JSON map may bypass the gate; treat any custom path as
  evidence that the project owns the gate manually, not that the prompt
  enforces it.
- The OpenSpec CLI package is pinned at the entry point to `1.5.0`; revalidate
  the fixture and regenerated command surface before intentionally upgrading it.
