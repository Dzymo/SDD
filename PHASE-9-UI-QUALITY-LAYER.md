# Phase 9 UI Quality Layer

Date: 2026-08-04

## Status

Phase 9 is **runtime-verified**. The reviewed
Designer and Observer prompt contracts, `ui-quality` skill, fixtures, and
offline evaluator pass. It establishes authority ordering for product truth,
durable design decisions, and approved surface briefs; adds bounded Designer
and Observer review contracts; and provides deterministic UI evidence
fixtures. It does not install Impeccable, add project dependencies, make a
global configuration write, or treat a synthetic score as proof.

The managed-runtime verifier passed again on 2026-08-05. It confirms the
installed prompts and Designer skill permission, not a rendered project result.
The 2026-08-05 active-global runtime record is the historical evidence for the
previous immutable Phase 12 candidate
`b75043d6097d12ac52c5bbbc3224f316c3243961`. The current PR head is
source-verified and isolated managed-runtime-verified only; the active-global
hash/apply/runtime verification has not been re-run against the current PR
head, and no global write has been performed for the current PR head.

## Delivered Assets

| Asset | Purpose |
|---|---|
| `docs\ui-quality-layer.md` | Authority order, selected patterns, evidence boundaries, and final user approval rule. |
| `skills\ui-quality\SKILL.md` | Reusable Designer workflow for direction, checks, review, and approval. |
| `prompts\oh-my-opencode-slim\sdd-personal\designer.md` | Replaces the generic Designer prompt with the phase policy. |
| `prompts\oh-my-opencode-slim\sdd-personal\observer.md` | Defines read-only, fresh screenshot-review output. |
| `templates\project\docs\surfaces\README.md` | Project-local surface-brief template and authority reminder. |
| `fixtures\phase-9\ui-review-scenarios.json` | Direction-preservation, machine-evidence, approval, and synthetic-score scenarios. |
| `scripts\Test-UIQualityLayer.ps1` | Offline evaluator for the source contracts. |
| `scripts\Apply-UIQualityLayer.ps1` | Fail-closed global apply with a per-file backup, SHA-256 manifest, narrow `designer.skills` merge, and automatic restoration on mismatch. |
| `scripts\Test-UIQualityLayerRuntime.ps1` | Read-only managed-runtime validation for both prompts and Designer's `ui-quality` permission. |

## Source Provenance

| Need | Repositories and paths inspected | Candidate mechanism | Decision | Reason | Verification |
|---|---|---|---|---|---|
| Product, design, and surface authority | `D:\Projects\Docs\impeccable\skill\reference\new-work.md` | Product truth, durable `DESIGN.md`, and route-specific surface brief | adapt | Separates durable facts from one-surface composition without inventing another workflow controller. | Fixture requires all three authorities and preserved fidelity. |
| Deterministic UI risk detection | `D:\Projects\Docs\impeccable\README.md`; `cli\engine\detect-antipatterns-browser.js`; `cli\engine\design-system.mjs` | Detector and design-system findings | adapt | Useful repeatable signal for drift, contrast, overflow, and generated patterns when a project already uses it. | Guide and prompt prohibit using a score or clean detector result as proof. |
| Fresh visual review | `D:\Projects\Docs\impeccable\skill\agents\impeccable-finish-reviewer.md`; `skill\reference\new-work.md` | Separate, read-only screenshot reviewer with a direction contract | adapt | Avoids implementation-thread bias while retaining human approval as the subjective decision. | Fixture requires an independent closed desktop/mobile review. |
| Contextual anti-generic heuristics | `D:\Projects\Docs\taste-skill\skills\taste-skill\SKILL.md` | Brief-led, contextual rules | adapt | Prevents generic UI without imposing universal font, color, motion, or layout rules on established products. | Skill and prompt require contextual use and deliberate exceptions. |

Rejected: installing the full Impeccable workflow globally, copying its commands
or hooks, adding a synthetic quality score, requiring a new browser stack, and
treating detector output as a release gate. These would add dependencies or a
second visual authority without proving a better outcome for each project.

## Source-Gate Hardening

The Phase 9 evaluator (`Test-UIQualityLayer.ps1`) now owns the verdict
expectations and the fixed scenario coverage in code. The fixed scenario
list is the canonical four-record coverage; the evaluator rejects a
fixture set with duplicate scenario names, missing required scenarios, or
unexpected scenarios. `Get-UiQualityVerdict` continues to classify a record
that claims a synthetic-score proof as `SYNTHETIC-SCORE-REJECTED` even when
every other authority, machine check, and screenshot field is present, and
the test asserts that classification is preserved. Negative-mutation checks
exercise each rejection class against an in-memory mutated fixture set so
the gate fails loudly when coverage drifts.

## Evidence Path

The claim is that a material UI change can retain its selected direction while
machine checks, independent visual review, and human approval remain distinct.
The offline evaluator checks finite evidence records and source contracts. It
cannot render a participating application; real project screenshots and native
checks remain required before asking for final visual approval.

| Claim | Source/tool | Evidence | Result |
|---|---|---|---|
| Selected direction persists through evidence collection | Phase 9 fixture and evaluator | `PRODUCT.md`, `DESIGN.md`, approved surface brief, and preserved fidelity are required. | Established for source policy. |
| Desktop/mobile/browser/accessibility evidence is required | Phase 9 fixture and evaluator | Missing mobile evidence cannot reach review-ready status. | Established for source policy. |
| Independent review and user approval are distinct | Phase 9 fixture and evaluator | Closed review yields `READY-FOR-HUMAN-APPROVAL`; only explicit approval yields `UI-APPROVED`. | Established for source policy. |
| Synthetic score is not proof | Phase 9 fixture and evaluator | A score-backed record is rejected even when other fields are present. | Established for source policy. |

## Verification

Run from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-UIQualityLayer.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayer.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-FrameworkSkeleton.ps1
```

The Phase 9 evaluator is offline and read-only. It does not start a browser,
call a model, create screenshots, add dependencies, or write global
configuration. It confirms only the framework source policy; project-native
checks and final user approval remain necessary in an actual UI change.

## Controlled Activation

After OpenChamber and CPA GUI are closed, run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-UIQualityLayer.ps1
```

It changes only the framework-owned slim configuration's
`presets.sdd-personal.designer.skills`, the Designer and Observer prompt files,
and `skills\ui-quality\SKILL.md`. It creates a timestamped `phase-9-*`
file-level backup plus a SHA-256 manifest, and restores changed targets if the
written configuration or copied files do not match their reviewed source.

Restart OpenChamber, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-UIQualityLayerRuntime.ps1
```

The runtime check proves the managed plugin initialized, the effective Designer
and Observer prompts contain the Phase 9 contracts, and Designer has permission
to load `ui-quality`. Do not install Impeccable or edit a participating project
as part of activation.

## Remaining Uncertainty

- The offline evaluator proves source-policy decisions, not the quality of an
  arbitrary rendered UI or a model's exact adherence to the prompt.
- Browser, accessibility, and screenshot capture commands differ by project;
  this layer deliberately uses project-native tooling instead of adding a global
  runner.
- User visual approval remains subjective and must be explicitly recorded.
