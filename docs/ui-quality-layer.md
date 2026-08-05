# UI Quality Layer

## Purpose

Phase 9 makes user-visible work preserve an approved direction without turning a
detector, screenshot, or model critique into false proof. It supplies a bounded
Designer policy, a reusable `ui-quality` skill, surface-brief guidance, a
screenshot-review contract, and an offline evaluator. It does not install
Impeccable, add browser or accessibility dependencies, change a project, or
activate a global prompt.

## Authority Order

1. `PRODUCT.md` owns product truth: users, outcomes, claims, constraints, and
   accessibility requirements.
2. `DESIGN.md` owns durable visual-system decisions: tokens, typography,
   components, interaction conventions, and brand commitments.
3. `docs/surfaces/<surface>.md` owns a selected route/screen/flow direction:
   composition, first viewport, assets, surface interactions, and unresolved
   decisions.
4. The task brief and implementation execute these authorities. They cannot
   silently override a higher authority.

For a small extension, inherit the established surface. For a new or material
redesign with no approved direction, present at most three structurally distinct
directions and wait for the user's selection unless they explicitly delegate it.
Direction selection is not final visual approval.

## Surface Brief

`templates\project\docs\surfaces\README.md` supplies the project-local format.
It remains short and contains scope, audience/task, primary action, constraints,
the user-approved direction, first-viewport reading order, required assets and
states, what must be preserved, and unresolved decisions. It must not duplicate
the product truth or design-system tokens already owned above it.

## Selected Impeccable Patterns

The framework adapts, but does not install or make a gate of, these mechanisms:

| Need | Selected pattern | Use | Limit |
|---|---|---|---|
| Preserve design-system decisions | `DESIGN.md` token checks | Investigate font, color, radius, and type-ramp drift when the detector is already available. | Findings can be false positives and require context. |
| Detect repeatable UI risks | Browser/static anti-pattern detector | Inspect contrast, overflow, heading structure, visibility, and selected generated-UI tells. | It does not judge product fit, composition, or user preference. |
| Review the chosen design | Fresh finish-review pattern | Give an independent reviewer the direction contract and desktop/mobile screenshots. | The reviewer does not edit and does not replace user approval. |
| Keep anti-generic heuristics proportionate | Taste contextual rule | Apply a heuristic only when the approved direction, audience, and constraints support it. | No font, color, motion, or layout ban is universal. |

When an approved project already has Impeccable, run its relevant detector command
and triage every finding. Do not add the package merely to satisfy this process.
Never use its audit score, a synthetic critique score, or a clean detector result
as proof that the UI is complete.

## Desktop And Mobile

Capture representative screenshots from the running surface after the final
implementation pass. Record the desktop and narrow-mobile viewport sizes and
the screenshot paths. On mobile, inspect reading order, overflow, responsive
collapse, text wrapping, and touch-target suitability. The screenshot is visual
evidence only; it does not prove browser behavior by itself.

## Browser And Accessibility

Use the participating project's existing commands and tooling. Record the exact
command, exit result, and relevant output separately for:

- browser/user-flow behavior, including relevant console and network errors;
- automated accessibility checks when present;
- keyboard focus/order, semantic landmarks and heading order, labels, contrast,
  and motion reduction appropriate to the changed UI.

Do not introduce a browser runner or accessibility dependency without a separate
project decision. A project command proves only the behavior it actually covers;
record an unavailable check as a limitation instead of fabricating PASS.

## Independent Screenshot Review

After an implementation pass, give a fresh, read-only reviewer the request,
changed paths, `PRODUCT.md`, `DESIGN.md`, approved surface brief, desktop/mobile
screenshots, and relevant browser, accessibility, or detector findings. Its
report is findings-first and answers whether the selected direction and first
viewport were preserved, which material visible issues remain, and what must not
be diluted during repair. The reviewer cannot edit and cannot grant approval.

Apply material fixes in one bounded pass, then collect final evidence. Passing
machine checks and a closed independent review establish only
`READY-FOR-HUMAN-APPROVAL`. The user must explicitly approve the visual result
before the record can state `UI-APPROVED`; silence, an earlier direction choice,
or any synthetic score is not proof.
