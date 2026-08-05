# Personal OpenCode Workflow Framework

Private source workspace for the global OpenCode framework used through
OpenChamber. It is not a package, marketplace extension, or distribution
project.

## Status

Phase 2's source-only framework skeleton has passed its layout and safety
verification; see `PHASE-2-FRAMEWORK-SKELETON.md`. Phase 3's Context7 OAuth and
CodeGraph MCP layer is active and runtime-verified; see
`PHASE-3-RESEARCH-LAYER.md` for scope, fallback limits, and rollback evidence.
The disabled-MCP section separates config inspection from the
prompt-based behavioral assertion; live model behavior under the disabled
state is a manual gate, not a runtime-verified claim.

Phase 4 applies the reviewed, non-secret source for the lean personal agent
preset: pinned slim registration, model fallbacks, prompt replacements, and
enforced read-only specialist permissions. The runtime verifier now inspects
Observer permissions equivalently to Explorer, Librarian, and Oracle. The
required agents and the updated permission verifier passed again on
2026-08-05. See `docs/agent-layer.md` for its
controlled global targets, validation, and rollback procedure.

Phase 6 adds a project-local OpenSpec bootstrap with default `spec-driven`
configuration, generated OpenCode core commands, concise evidence templates,
and a strict-validation fixture. See `PHASE-6-OPENSPEC-PROJECT-TEMPLATE.md`.

Phase 7 adds bounded task-brief, M3 Fixer, risk-triggered Oracle, two-attempt
repair, and truthful-completion contracts. Its offline fixture gate rejects a
PASS record containing a failed command. Its controlled global apply and
managed-runtime verifier passed on 2026-08-05; see
`PHASE-7-EXECUTION-AND-VERIFICATION.md`.

Phase 8 adds concise OpenChamber operating guidance for Focus Mode, Session
Goals, worktrees, and MultiRun. Its offline fixture gate checks recommendations,
Goal safety boundaries, and the single continuation controller. Its controlled
global apply and hash-based managed-runtime verifier passed on 2026-08-05. See
`PHASE-8-OPENCHAMBER-OPERATING-GUIDE.md`.

Phase 9 adds an evidence-led UI quality layer: product/design/surface authority,
contextual detector heuristics, desktop/mobile/browser/accessibility evidence,
fresh screenshot review, and explicit human visual approval. Its offline gate
rejects a synthetic score as proof. Its managed-runtime verifier passed again
on 2026-08-05; see `PHASE-9-UI-QUALITY-LAYER.md`.

Phase 10 adds package and release contracts: project-local package command
configuration, clean temporary-environment install/run evidence, checksum and
delivered-content checks, explicit approval before an external action, and
strict OpenSpec archive after a successful release. Its fixture packages and
installs a local artifact without contacting a registry. Phase 10 is
**source-complete**; the historic 2026-08-04 record of the controlled
activation and managed-runtime verification is retained for provenance. The
managed-runtime verification is a required residual gate and has not been
re-run in this update. See `PHASE-10-PACKAGING-AND-RELEASE.md`.

Phase 11 adds 18 deterministic evaluation and failure drills across questions,
UI direction, research fallbacks, worker scope, repair escalation, truthful
completion, package/release safety, Goals, writer ownership, stale assumptions,
fan-out, and scoped review. Phase 11 is **source-complete**; the offline
evaluator is a source-policy regression guard and does not prove live model
compliance. See `PHASE-11-EVALUATION-AND-FAILURE-DRILLS.md`.

Phase 12 global rollout is **unstarted**. Its required gates (final backups,
dry-run/diff preview, controlled global apply, restart, smoke tests, rollback
drill, active versions and checksums) are listed in `PLAN.md` and none has been
performed in this update.

## Layout

| Path | Purpose |
|---|---|
| `PHASE-*.md` | Phase-specific verification evidence and scope limits. |
| `docs/` | Architecture, decisions, operations, evaluation index, and rollback procedure. |
| `config/` | Future reviewed, non-secret framework configuration sources. |
| `prompts/`, `skills/`, `commands/` | Future reusable global behavior. |
| `templates/` | Project-local product, design, and OpenSpec bootstrap assets. |
| `scripts/` | Safe repository checks and future lifecycle tooling. |
| `evals/` | Reproducible evaluation evidence. |
| `fixtures/` | Small, isolated verification inputs. |

## Operating Rules

1. `PLAN.md` is the implementation source of truth.
2. Keep product facts and OpenSpec change history in each participating project.
3. Never copy provider credentials, OpenChamber settings, sessions, relay data,
   runtime state, or protected backups into this workspace.
4. Do not apply a global configuration change until its owner, target, backup,
   validation command, and rollback have been recorded.

## Check The Skeleton

Run from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-FrameworkSkeleton.ps1
```

The check validates the required layout, permits only the reviewed source schema
under `config/`, and scans committed text for common credential markers. It does
not read any user configuration directory.

## Validate The Research Schema

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ResearchConfigSchema.ps1
```

The validator accepts the approved Context7 OAuth and local CodeGraph MCP
fragment, and rejects an authentication header, altered CodeGraph command, and
non-OAuth Context7 endpoint.

Run the managed runtime gate after changing the MCP source, CodeGraph install,
or OpenCode version:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ResearchRuntime.ps1
```

## Validate The Agent Layer

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayer.ps1
```

This checks the source-level plugin pin, role routes and fallbacks, disabled
automation features, read-only permissions, and prompt rules. After the global
apply and OpenChamber restart, run `Test-AgentLayerRuntime.ps1` to validate the
effective managed runtime.

## Check Multimedia Readiness

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-MultimediaCapabilities.ps1
```

This confirms that GPT routes remain text-only and M3 supports image/video but
not PDF. It also verifies the enabled M3 Observer route. See
`PHASE-5-MULTIMEDIA.md` for the cache patch, structured attachment evidence,
and revalidation procedure.

## Regress Observer Handoff

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachmentRegression.ps1
```

This offline source gate protects the `image_routing: auto` preset, the
Orchestrator and Observer prompt contracts, the child-session patch record, and
the OCR smoke contract. GitHub Actions runs it on pull requests. Run the live
M3 integration smoke with `Test-ObserverAttachment.ps1` after a plugin update
or reinstall; it generates a new image with a unique visible code and verifies
that M3 returns it.

## Run Local M3 OCR Smoke

The smoke uses the managed OpenChamber CLI, never prints a credential, and
performs these preflight checks before creating an image or calling a model:

1. The managed executable and workspace exist.
2. Effective runtime config has an enabled Observer routed to
   `minimax-coding-plan/MiniMax-M3`, with the current structured-attachment
   prompt contracts loaded.
3. `auth list` reports a MiniMax credential without revealing its value.
4. M3 metadata is active and declares both image input and attachments.

Run it from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachment.ps1
```

Expected output first includes `Observer OCR preflight: PASS`, followed by
`Observer structured attachment smoke: PASS`. If the preflight fails, restore
the managed route or credential first; do not bypass it by putting a token in
this repository or changing the test to call an unmanaged CLI.

## Test OCR Preflight Failures

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachmentPreflight.ps1
```

This offline test uses a temporary mock CLI and verifies clear failures for a
missing binary or workspace, a failed or invalid runtime config, disabled
Observer, wrong M3 route, both missing prompt contracts, missing MiniMax
credential, and inactive M3 image metadata. Every negative case also verifies
that its credential sentinel is absent from the error output. It runs in the
Windows pull-request workflow and makes no provider call.

## Validate OpenSpec Template

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenSpecProjectTemplate.ps1
```

This runs strict validation against the isolated Phase 6 fixture using the
pinned `@fission-ai/openspec@1.5.0` CLI. It does not write OpenCode or
OpenChamber configuration. Copy `templates/project/` into a participating
project to begin a project-local OpenSpec workflow. Before using the generated
slash commands, install the reviewed CLI on `PATH` and restart or reload
OpenCode; see `templates/project/README.md` and the Phase 6 end-to-end record.

The copied bootstrap includes its own preflight. Run it from that project to
fail fast on a missing or version-mismatched OpenSpec CLI and to show known
generated-command dependencies that the `core` profile does not provide:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\Test-OpenSpecBootstrapPreflight.ps1
```

## Validate Execution And Verification

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ExecutionVerification.ps1
```

This offline source gate validates the Phase 7 task-brief and agent contracts.
It accepts a passing feature and a bug with regression evidence, requires Oracle
assumption review after two failed repairs, and blocks a completion record that
claims PASS despite a failed validation command.

## Validate OpenChamber Operating Guidance

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenChamberOperatingGuide.ps1
```

This offline source gate validates routine, Focus, Goal, worktree, MultiRun,
and release-boundary advisory scenarios. It also requires the Orchestrator to
leave Goal activation and continuation to the user/OpenChamber, with slim idle
continuation disabled.

After the controlled global prompt apply and OpenChamber restart, verify the
active target without changing it:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenChamberOperatingGuideRuntime.ps1
```

The controlled apply command is `Apply-OpenChamberOperatingGuide.ps1`. It
refuses while OpenChamber or managed OpenCode is running, makes a file-level
backup with hashes, and changes only the framework-owned Orchestrator prompt.

## Validate UI Quality Layer

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-UIQualityLayer.ps1
```

This offline source gate requires the `PRODUCT.md`/`DESIGN.md`/surface-brief
authority chain, desktop/mobile/browser/accessibility evidence, and a separate
closed screenshot review. It leaves the result at `READY-FOR-HUMAN-APPROVAL`
until an explicit user approval is recorded, and rejects a synthetic score as
proof. It does not run a browser, capture an image, install Impeccable, or write
global configuration.

## Validate Packaging And Release

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingRelease.ps1
```

This offline source gate packs a local fixture, installs it in a new temporary
environment with install scripts disabled, runs a smoke check, checks its
SHA-256 and delivered contents, and verifies release approval and archive
records. It cannot publish, deploy, tag, push, merge, or call a registry.

After the controlled global prompt/skill apply and OpenChamber restart, verify
the active targets without changing them:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingReleaseRuntime.ps1
```

## Validate Evaluation And Failure Drills

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-EvaluationFailureDrills.ps1
```

This offline gate derives the expected verdict for every Phase 11 scenario and
checks the cross-phase source contracts. It does not call a provider, change
global configuration, create a worktree, or release anything. It is a policy
regression guard, not proof of every future model response or project runtime.

## Pull Request Gate

GitHub Actions runs the research schema, agent-layer source, execution and
verification, OpenChamber operating guide, UI quality layer, package and
release fixture, evaluation and failure drills, Observer attachment regression,
copied OpenSpec bootstrap preflight using the exact `1.5.0` CLI, and framework
safety verifiers on Windows for every pull request through
`.github/workflows/research-config.yml`. Configure
`Validate research MCP schema (Windows)` as a required check in the repository's
target-branch protection rule to prevent a pull request with an invalid MCP
configuration from merging.

The workflow uses `windows-latest` so the checks run in the same PowerShell and
path environment as the managed installation.

Dependabot checks GitHub Actions weekly on Monday and opens update pull requests
when an action version or its pinned SHA changes. Review each update's upstream
release and keep the SHA pin before merging it through the Windows gate.

See `docs/operations.md` for the future source, staging, apply, check, and
rollback lifecycle.
