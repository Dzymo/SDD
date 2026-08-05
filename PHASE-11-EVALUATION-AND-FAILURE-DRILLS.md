# Phase 11 Evaluation And Failure Drills

Date: 2026-08-04

## Status

Phase 11 source implementation is **source-complete**. The deterministic
offline failure-drill gate, the 18 required scenarios, and the cross-phase
source-contract checks all pass without a provider call, a global
configuration write, a worktree operation, or an external release action.

## Limitation

The offline evaluator is a source-policy regression guard. It proves that the
fixed source records and contracts classify each scenario correctly and that
mutating one essential safe condition causes the same scenario to be
classified as a failure. It does **not** prove that any specific live model
will follow the corresponding prompt in a future, unobserved task; that
remains a manual gate and a project-specific responsibility. The
Context7/CodeGraph failure drills inspect the effective disabled configuration
and the disabled-state prompt contract, not live model behavior under the
disabled state.

## Delivered Assets

| Asset | Purpose |
|---|---|
| `fixtures\phase-11\failure-drills.json` | One deterministic record for every required normal and failure scenario. |
| `scripts\Test-EvaluationFailureDrills.ps1` | Derives each verdict, rejects missing/duplicate drills, mutation-tests one unsafe condition per drill, and checks relevant source contracts. |
| `docs\evaluation-and-failure-drills.md` | Drill matrix, safety boundary, command, and limitations. |
| `.github\workflows\research-config.yml` | Runs the evaluator on Windows pull requests. |

## Source-First Decision

| Field | Record |
|---|---|
| Need | Exercise cross-phase safety behavior without creating a second workflow engine or changing the managed runtime. |
| Repositories inspected | Existing Phase 7-10 evaluators and fixtures in this repository; Phase 2 architecture provenance for deterministic fixed-input evaluation. |
| Candidate mechanism | Phase 7 verdict function plus Phase 8-10 static source-contract gates. |
| Decision | Adapt. |
| Reason | A small PowerShell verdict evaluator and JSON fixture reuse the established gate pattern, remain deterministic, and avoid provider-dependent test results. |
| Rejection | Live provider failure injection would be nondeterministic, could consume quota, and cannot safely simulate every global-runtime failure in CI. |
| Verification | Run the Phase 11 evaluator together with affected Phase 7-10 and framework safety gates. |

## Safety Evidence

The evaluator blocks false success when a test or clean smoke fails, blocks a
worker that writes outside its brief, blocks an external release without exact
approval, prevents duplicate Goal continuation while Evaluating, rejects
overlapping writers, and requires explicit Context7/CodeGraph fallback states.
It also confirms that routine/trivial work avoids Deepwork and fan-out while a
named public auth boundary receives one scoped, read-only Oracle review.
For every fixture, it mutates one essential safe condition and requires the
result to be `DRILL-FAILED`; the expected verdict matrix lives in the evaluator
so fixture data cannot redefine a safe outcome.

## Verification

Run from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-EvaluationFailureDrills.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ExecutionVerification.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenChamberOperatingGuide.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-UIQualityLayer.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingRelease.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayer.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-FrameworkSkeleton.ps1
```

The Phase 10 gate is the only command above that creates temporary package and
clean-install directories. It removes them and does not contact a registry.

## Remaining Limitations

- The gate cannot prove future model compliance, live MCP outages, or every
  application-specific failure mode.
- An updated framework-owned prompt or preset still needs its normal controlled
  apply, OpenChamber restart, and managed-runtime verifier before it is active.
- The fixture's high-risk review is a policy decision; a real project must name
  its actual risk and run project-native focused validation.
