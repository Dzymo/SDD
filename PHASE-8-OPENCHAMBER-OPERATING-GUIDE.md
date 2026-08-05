# Phase 8 OpenChamber Operating Guide

Date: 2026-08-04

## Status

Phase 8 is **runtime-verified**. The reviewed
Orchestrator prompt contract, advisory guide, fixtures, and offline evaluator
pass. It adds bounded Orchestrator advice for Focus Mode, Session Goals,
worktrees, and MultiRun; a user operating guide; and deterministic advisory
fixtures.

It does not change OpenChamber settings, arm Goals, create worktrees, enable permissions, or add a continuation loop. The controlled prompt apply completed on 2026-08-05 with backup `phase-8-20260805-180815`; the hash-based managed-runtime verifier then passed.

## Delivered Assets

| Asset | Purpose |
|---|---|
| `docs\openchamber-operating-guide.md` | Mode selection, Goal objective template, status/budget behavior, limits, and project-memory conventions. |
| `prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md` | Conditional recommendations and prohibitions on silent Goal, budget, continuation, worktree, and MultiRun misuse. |
| `fixtures\phase-8\advisory-scenarios.json` | Positive and negative advisory scenarios. |
| `scripts\Test-OpenChamberOperatingGuide.ps1` | Offline evaluator for scenarios, prompt rules, and the sole-continuation-controller configuration. |
| `scripts\Apply-OpenChamberOperatingGuide.ps1` | Fail-closed global activation: process guard, file-level backup, SHA-256 manifest, and restore on copy mismatch. |
| `scripts\Test-OpenChamberOperatingGuideRuntime.ps1` | Read-only managed-runtime check for the active global prompt after restart. |

## Source Provenance

| Need | Repositories and paths inspected | Decision | Reason | Verification |
|---|---|---|---|---|
| Goal status, budget, pause, resume, and limits | `D:\Projects\Docs\openchamber\packages\docs\content\docs\session-goals.mdx` | Reuse native Session Goals | OpenChamber owns auditing, continuation, pause/resume, budgets, and notifications. | Gate requires `continueOnIdle: false` and Goal safety rules. |
| Isolated implementation sessions | `D:\Projects\Docs\openchamber\packages\docs\content\docs\worktrees.mdx` | Reuse native worktree sessions | OpenChamber owns branch, folder, integration, and cleanup. | Gate requires the slim worktree skill to remain disabled. |
| Alternative comparison | `D:\Projects\Docs\openchamber\packages\docs\content\docs\multi-run.mdx` | Adapt isolated MultiRun | Independent alternatives are safe only with distinct writer worktrees. | Fixtures require comparison value, isolation, and a user decision. |
| Contextual user advice | `PLAN.md` sections 14 and 19; preset Orchestrator replacement | Adapt prompt rules plus guide | Advice can occur at the decision point without owning user controls. | Prompt-contract and fixture evaluator. |

## Source-Gate Hardening

The Phase 8 advisory evaluator (`Test-OpenChamberOperatingGuide.ps1`) now
owns the verdict expectations and the fixed scenario coverage in code. The
fixed scenario list is the canonical list of nine situations; the evaluator
rejects a fixture set with duplicate scenario names, missing required
scenarios, unexpected scenarios, or a scenario whose `situation` does not
match the code-owned expectation. `Get-AdvisoryVerdict` returns
`unknown-situation` for any situation outside the reviewed switch, and the
test asserts that classification is preserved. Negative-mutation checks
exercise each rejection class against an in-memory mutated fixture set so
the gate fails loudly when coverage drifts.

Rejected: a plugin or prompt-managed continuation loop, a second worktree manager, and MultiRun for routine implementation. Each would duplicate an OpenChamber responsibility or increase writer-conflict cost without a benefit.

## Evidence Path

The claim is that source policy recommends the smallest appropriate OpenChamber mode, never silently activates user controls, and leaves automatic continuation to Session Goals alone. The deterministic evaluator classifies finite scenarios and checks non-negotiable prompt/config rules. Runtime validation after global apply is still necessary because an LLM may not perfectly follow a prompt.

| Claim | Source/tool | Evidence | Result |
|---|---|---|---|
| Routine and unresolved work do not receive an unsafe Goal | Phase 8 fixtures and evaluator | Small-question, unresolved-UI, and incomplete-Goal scenarios classify to no Goal or missing preconditions. | Established for source policy. |
| Approved bounded work receives Worktree + Goal advice | Phase 8 fixtures and evaluator | Objective, evidence, resolved decisions, safe continuation, and budget classify as `worktree-goal`. | Established for source policy. |
| MultiRun writers remain isolated | Phase 8 fixtures and evaluator | Comparison requires value, isolated writers, and a user decision. | Established for source policy. |
| Goals are not silently armed and continuations are not duplicated | Prompt/config contract | Prompt forbids arm/resume/budget/continuation action; slim idle continuation is `false`. | Established for source policy. |

## Verification

Run from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenChamberOperatingGuide.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayer.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-FrameworkSkeleton.ps1
```

The Phase 8 evaluator is offline and read-only. It does not call a provider, modify global configuration, start an OpenChamber Goal, or create a worktree.

## Controlled Global Activation

Only the reviewed Orchestrator prompt changes. After OpenChamber and CPA GUI are closed, use the fail-closed activation script. It creates a timestamped file-level backup and SHA-256 manifest before copying only the reviewed prompt:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-OpenChamberOperatingGuide.ps1
```

It refuses to run while an OpenChamber, CPA GUI, or managed OpenCode process is active. Restart OpenCode/OpenChamber, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayerRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenChamberOperatingGuideRuntime.ps1
```

`Test-OpenChamberOperatingGuideRuntime.ps1` hash-compares the active global
Orchestrator prompt with the reviewed Phase 8 source before checking the
required rule substrings. A hash mismatch is a fail-closed condition that
means a manual edit drifted the active prompt from the reviewed source.
The runtime step passed on 2026-08-05.

Do not edit `C:\Users\quang\.config\openchamber`, OpenChamber session state, or `opencode.json` for this phase. Manually exercise one normal-chat recommendation and one self-contained Goal in a disposable project before treating the guidance as runtime-observed behavior.

## Rollback

Restore only the target prompt from the `phase-8-*` backup created by the
activation script, restart OpenChamber, and run `Test-AgentLayerRuntime.ps1`.
The backup manifest records its before/source/after SHA-256 values. Do not
restore a directory or modify OpenChamber state; see `docs/rollback.md`.

## Remaining Uncertainty

- The evaluator validates source rules and classifications, not arbitrary model compliance.
- Token budget sizing is user- and task-specific; the guide supplies boundaries, not a universal number.
- Focus Mode's visual shortcut and UI can change with OpenChamber releases; verify the installed version before changing the guide.
