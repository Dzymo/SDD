# Phase 10 Packaging And Release

Date: 2026-08-04 (source complete), residual gates tracked 2026-08-05

## Status

Phase 10 is **runtime-verified**. Its source contracts, fixtures, and offline
evaluator provide a project-local package contract,
deterministic clean-install fixture, checksum and delivered-content checks,
verification/release templates, explicit approval gating for external
actions, and strict post-release OpenSpec archive rules.

The controlled global activation was rerun on 2026-08-05 with backup
`phase-10-20260805-180819`, and `Test-PackagingReleaseRuntime.ps1` passed
against the managed runtime. The offline evaluator is provider-free; it packs a local fixture, installs it
into a fresh temporary directory, computes its SHA-256, and checks
delivered-content rules without contacting a registry.

It does not publish, deploy, tag, push, merge, call a registry, or write a
global target. Global activation remains a separate controlled operation and an
actual project release always needs a fresh explicit user approval. The
2026-08-05 active-global runtime record is historical evidence for Phase 12
candidate `b75043d6097d12ac52c5bbbc3224f316c3243961`. Later active runtime
verification passed, and the clean `e5bb0ed...` readiness preflight found the
Phase 10 targets matched reviewed source. No reapply was required.

## Delivered Assets

| Asset | Purpose |
|---|---|
| `docs\packaging-and-release.md` | Package contract, clean-environment, content, approval, archive, and rollback policy. |
| `templates\project\PACKAGE.md` | Project-local configuration for package, smoke, content-check, release, and rollback commands. |
| `templates\openspec\verification.md` | Records package evidence next to requirement coverage. |
| `templates\openspec\release.md` | Captures exact approval, release result, strict validation, and archive evidence. |
| `skills\package-and-release\SKILL.md` | Reusable execution sequence that stops for explicit user approval. |
| `prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md` | Requires package gate evidence and blocks external actions without approval. |
| `fixtures\phase-10\clean-package\` | Local dependency-free artifact fixture for actual clean install/run evidence. |
| `fixtures\phase-10\release-scenarios.json` | Deterministic approval, smoke failure, content finding, and archive scenarios. |
| `scripts\Test-PackagingRelease.ps1` | Offline source evaluator plus actual local clean-artifact smoke. |
| `scripts\Apply-PackagingRelease.ps1` | Fail-closed controlled prompt/skill apply with file-level backup and hash manifest. |
| `scripts\Test-PackagingReleaseRuntime.ps1` | Read-only managed-runtime validation after a controlled apply and restart. |

## Evidence Path

The framework claim is that a deliverable is checked as an artifact, not merely
as source code, and that an agent cannot treat that evidence as permission for
an external release. The evaluator copies a local fixture into a fresh system
temporary directory, runs `npm pack --json --ignore-scripts`, computes the
artifact SHA-256, installs the artifact into a separate temporary directory
with install scripts disabled, requires the installed package, and checks names
and text for prohibited delivered material. It does not use a registry.

| Claim | Source/tool | Evidence | Result |
|---|---|---|---|
| Artifact is independently runnable | Clean fixture and `Test-PackagingRelease.ps1` | Packed local artifact installs into a new temporary environment and returns its expected smoke value. | Established for the framework fixture. |
| Checksum and delivered-content checks are required | Evaluator and release scenarios | SHA-256 is computed; prohibited names/content are scanned; a content finding blocks the scenario. | Established for source policy. |
| Release requires explicit approval | Release scenarios and Orchestrator/skill contract | Passing package with no approval is classified `RELEASE-APPROVAL-REQUIRED`. | Established for source policy. |
| Archive follows the applicable branch | Release scenarios | A release-applicable change needs a successful external result, post-release smoke, strict validation, and archive command for `RELEASE-ARCHIVED`. A genuine no-external-release change needs full coverage, focused validation, strict validation, and `releaseApplicable: false` evidence for `NON-RELEASE-ARCHIVED`. | Established for source policy. |

The evaluator's content patterns are a bounded guard, not proof that every
possible sensitive value is absent. Participating projects must use their own
appropriate content checks and record limitations.

## Source-Gate Hardening

The Phase 10 evaluator (`Test-PackagingRelease.ps1`) now owns the verdict
expectations and the fixed scenario coverage in code. The fixed scenario
list is the canonical five-record coverage; the evaluator rejects a
fixture set with duplicate scenario names, missing required scenarios, or
unexpected scenarios. `Get-ReleaseVerdict` continues to require explicit
approval, an executed external result, strict OpenSpec validation, and a
clean archive for `RELEASE-ARCHIVED`, and the test asserts that stripping
the executed result collapses the scenario to `RELEASE-AUTHORIZED` rather
than letting it appear archived. Negative-mutation checks exercise each
rejection class against an in-memory mutated fixture set so the gate fails
loudly when coverage drifts.

## Verification

Run from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingRelease.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayer.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-FrameworkSkeleton.ps1
```

The Phase 10 evaluator is local and read-only with respect to the repository
and global configuration. It creates and removes only its own fresh temporary
fixture directories. It never publishes an artifact or invokes an external
release command.

The controlled activation was historically applied and, after restarting
OpenChamber, the following managed-runtime verification passed on 2026-08-04:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingReleaseRuntime.ps1
```

Result: `Phase 10 packaging and release runtime: PASS` (rerun 2026-08-05).
The offline evaluator passes; managed-runtime evidence must be refreshed after
any future framework package/release change before relying on it.

## Controlled Activation

After OpenChamber and CPA GUI are closed, run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-PackagingRelease.ps1
```

The script first validates the Phase 10 and agent-layer source, refuses to run
while managed processes are active, backs up only the global Orchestrator prompt
and `package-and-release` skill, writes a timestamped `phase-10-*` manifest,
verifies each copied SHA-256, and restores named changed targets after a failed
copy, hash check, or manifest write. It does not alter plugin configuration,
OpenChamber state, or any release target.

Restart OpenChamber, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingReleaseRuntime.ps1
```

## Rollback

Restore only the targets named in the `phase-10-*` backup manifest, removing a
target only where its manifest says the prior value was `ABSENT`, then restart
OpenChamber and run the runtime verifier. This changes framework instructions,
not an external release. A project release rollback remains its separately
approved, project-specific procedure in `PACKAGE.md` and `release.md`; see
`docs/rollback.md`.

## Remaining Uncertainty

- The local fixture proves this framework's clean-artifact path, not every
  package manager, installer, operating system, or project-specific smoke test.
- Static content checks reduce obvious delivery risk but do not replace a
  project-appropriate security review.
- Source and runtime checks validate contracts and active files, not perfect
  future model compliance. External release execution remains user-controlled.
