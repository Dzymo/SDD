# Phase 7 Execution And Verification

Date: 2026-08-04

## Status

Phase 7 is **runtime-verified**. The reviewed
source contracts, fixtures, and offline evaluator pass without introducing a
second workflow controller, automatic release action, default Oracle review, or
unbounded repair loop. The controlled apply completed on 2026-08-05 with backup
`phase-7-20260805-180814`; `Test-ExecutionVerificationRuntime.ps1` then
passed against the managed runtime.

The source and runtime evidence establish the installed contract, not arbitrary
model compliance in an unobserved future task. The 2026-08-05 active-global
runtime record remains historical evidence for Phase 12 candidate
`b75043d6097d12ac52c5bbbc3224f316c3243961`. Later active runtime verification
passed and the clean `e5bb0ed...` readiness preflight found every Phase 7 target
matched reviewed source, so no reapply was required. This target/hash refresh
does not replace focused verification in future project work.

## Delivered Assets

| Asset | Purpose |
|---|---|
| `prompts\oh-my-opencode-slim\sdd-personal\orchestrator.md` | Requires a complete task brief, routes bounded non-visual work to M3 Fixer, requires practical bug regression evidence, and escalates after two failed repairs. |
| `prompts\oh-my-opencode-slim\sdd-personal\fixer.md` | Binds the worker to allowed-file scope, focused validation, truthful status, and no third blind repair. |
| `prompts\oh-my-opencode-slim\sdd-personal\oracle.md` | Limits Oracle to named material risk or two-failure assumption review rather than default completion review. |
| `skills\systematic-debugging\SKILL.md` | Compact evidence-to-hypothesis repair loop with a two-repair stop condition. |
| `skills\verification-before-completion\SKILL.md` | Compact completion gate requiring fresh command output and exit-code inspection. |
| `fixtures\phase-7\` | Deterministic feature, bug, false-PASS, and escalation records. |
| `scripts\Test-ExecutionVerification.ps1` | Offline policy evaluator and prompt/config contract check. |
| `scripts\Apply-ExecutionVerification.ps1` | Fail-closed controlled global apply that merges only `presets.sdd-personal.fixer.skills` into the existing slim config, copies the five reviewed prompt/skill targets, records a per-file SHA-256 manifest, and rolls back on any write failure. |
| `scripts\Test-ExecutionVerificationApply.ps1` | Isolated apply regression proving unrelated slim configuration survives the merge and a later write failure restores the original config bytes. |
| `scripts\Test-ExecutionVerificationRuntime.ps1` | Read-only managed-runtime validation of prompts, skills, routes, and plugin initialization. |

## Source Provenance

| Need | Repositories and paths inspected | Candidate mechanism | Decision | Reason | Rejected alternative | Verification |
|---|---|---|---|---|---|---|
| Bounded worker and proportionate Oracle routing | `D:\Projects\Docs\oh-my-opencode-slim\src\agents\orchestrator.ts`; `src\agents\fixer.ts`; `src\agents\oracle.ts` | Replacement prompts and existing Fixer/Oracle roles | Adapt | Existing roles and M3 route already provide the required execution boundary. | New coordinator or plugin hook would duplicate slim/OpenChamber control. | Source gate checks M3 Fixer route and required prompt rules. |
| Root-cause repair policy | `D:\Projects\Docs\superpowers\skills\systematic-debugging\SKILL.md` | Four-phase debugging skill | Adapt | Retain direct evidence, one hypothesis, and stop-on-repeat failure; remove mandatory ceremony and third-attempt policy. | Copying the full skill conflicts with the framework's proportionate-work rule. | Two-failed-repairs fixture requires Oracle assumption review. |
| Truthful completion evidence | `D:\Projects\Docs\superpowers\skills\verification-before-completion\SKILL.md` | Evidence-before-claim completion gate | Adapt | Retain fresh commands, output, and exit-code requirements in a concise skill. | Trusting a worker report or a prior command result permits false completion. | False-PASS fixture is classified `FALSE-PASS-BLOCKED`. |

## Source-Gate Hardening

The Phase 7 source gate (`Test-ExecutionVerification.ps1`) now treats a PASS
record as a hard triple: a non-empty `taskId`, a brief that satisfies every
required field, and at least one validation attempt whose `command`,
`output`, and numeric `exitCode = 0` are all present and non-empty. A
validation whose `command` is empty, whose `output` is missing or empty, or
whose `exitCode` is not the integer zero cannot satisfy PASS. A record that
has no attempts, that lacks `taskId`, or that lets a missing-output or
empty-command validation slip through is classified `MISSING-TASK-ID`,
`FALSE-PASS-BLOCKED`, or `MISSING-REGRESSION-EVIDENCE` and the gate fails.
Negative-mutation fixtures in `fixtures\phase-7\` exercise each former
false-positive class.

## Evidence Path

The claim is that a bounded worker cannot legitimately record completion while
its required command has failed, and that repeated repair failure changes the
workflow from editing to assumption review. The source prompt cannot force an
LLM's future behavior by itself, so the durable evidence is a deterministic
evaluator plus explicit runtime revalidation after controlled global apply.

| Claim | Source/tool | Evidence | Result |
|---|---|---|---|
| Clear feature has no forced user question or Oracle review | `fixtures\phase-7\feature\record.json`; `Test-ExecutionVerification.ps1` | Complete brief, M3 Fixer, one successful focused command, `PASS`. | Established for the policy contract. |
| Bug has regression evidence | `fixtures\phase-7\bug\record.json`; `Test-ExecutionVerification.ps1` | Regression exit code is nonzero before the repair and zero afterward. | Established for the policy contract. |
| Two failures stop blind edits | `fixtures\phase-7\two-failed-repairs.json`; `Test-ExecutionVerification.ps1` | Two failed validation entries require `oracle` with `assumption-review` and `ESCALATE`. | Established. |
| Failed command cannot yield PASS | `fixtures\phase-7\failed-command-false-pass.json`; `Test-ExecutionVerification.ps1` | A record that sets `PASS` with exit code 1 is classified `FALSE-PASS-BLOCKED`. | Established. |

## Verification

Run from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ExecutionVerification.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ExecutionVerificationApply.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayer.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-FrameworkSkeleton.ps1
```

The Phase 7 evaluator is also a Windows pull-request gate. It is deliberately
offline: it never calls a provider, writes a global configuration target, or
mistakes a model response for command evidence. The source gate proves the
policy contract; the controlled apply and managed-runtime verifier recorded
above establish that the reviewed contract is installed. Neither is evidence
that an arbitrary future model response will follow every instruction.

## Controlled Global Activation Record

The fail-closed controlled apply completed on 2026-08-05. It validated the
Phase 7 and agent-layer source, backed up the existing slim configuration plus
the three reviewed prompt targets and two reviewed skill targets to
`phase-7-20260805-180814`, verified every after SHA-256, and would restore all
changed targets if a merge, copy, or manifest write failed. The slim config
operation changes only `presets.sdd-personal.fixer.skills`; it preserves the
existing Fixer model, unrelated Fixer fields, other agents, other presets, and
top-level configuration. It did not alter OpenChamber state or `opencode.json`.

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-ExecutionVerification.ps1
```

After restarting OpenCode/OpenChamber, the following runtime validation passed:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayerRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ExecutionVerificationRuntime.ps1
```

That runtime command validates active prompt and skill hashes, plugin
initialization, effective prompt contracts, and Fixer/Oracle registration. It
does not prove every prompt instruction will be followed in a future task.

## Remaining Uncertainty

- The offline evaluator proves records and source contracts, not arbitrary model
  compliance.
- A project must supply real focused test commands in each task brief; a fixture
  command name is not application evidence.
- A bounded real-project task remains the appropriate behavior smoke before a
  project relies on the workflow for a material change.
