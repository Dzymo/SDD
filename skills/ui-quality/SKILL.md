---
name: ui-quality
description: Evidence-led UI workflow for preserving an approved design direction across implementation, browser checks, screenshot review, and final human approval.
---

# UI Quality

Use this skill only for new user-visible surfaces, material visual redesigns, or UI changes with meaningful responsive or accessibility risk. Do not invoke it for a mechanical label, copy, or small style adjustment that can follow the established system directly.

## Authority

1. `PRODUCT.md` owns product facts, audience, claims, outcomes, and durable constraints including accessibility.
2. `DESIGN.md` owns durable visual-system decisions: tokens, typography, components, behavior conventions, and brand commitments.
3. `docs/surfaces/<surface>.md` owns the approved direction for one route, screen, flow, or artifact: task, chosen composition, first viewport, assets, and unresolved decisions.
4. The implementation brief and code execute these authorities. They cannot silently change a higher authority. Pause for a user decision when they conflict.

For an established surface, preserve its direction. For a new or materially redesigned surface, present no more than three distinct directions and obtain the user's choice before production code, unless the user explicitly delegates selection.

## Surface Brief

Create or update the relevant surface brief before implementation when a direction must persist. Keep it concise and include:

- scope, audience, user task, primary action, and non-negotiable constraints;
- selected direction, first-viewport composition, and what must remain recognizable;
- required asset treatment and interaction states;
- unresolved decisions and the date/source of user approval.

Do not copy product facts or design tokens into the brief. A direction selection is not final visual approval.

## Checks

Use existing project-native commands and browser tooling. Do not add a browser runner, an accessibility package, or Impeccable merely to satisfy this framework.

Record separate evidence for:

| Check | Minimum evidence |
|---|---|
| Desktop | Screenshot of the changed surface at a stated desktop viewport. |
| Mobile | Screenshot at a stated narrow viewport; inspect overflow, hierarchy, touch targets, and collapsed layouts. |
| Browser | The project-native smoke or browser flow; console and network errors relevant to the changed path are examined. |
| Accessibility | Existing automated accessibility check when available, plus keyboard focus/order, semantic structure, labels, contrast, and reduced-motion review appropriate to the change. |

Use the selected Impeccable mechanisms only when appropriate and already available: deterministic anti-pattern or design-system findings may identify drift in typography, tokens, hierarchy, contrast, overflow, or generated-UI patterns. Verify each finding in context. A detector is not a design critic, browser test, accessibility certification, or release gate. Do not use an audit score or synthetic critique score as evidence of quality.

## Independent Review

After the implementation pass, provide a fresh read-only reviewer with the original request, changed paths, `PRODUCT.md`, `DESIGN.md`, the surface brief, desktop and mobile screenshots, and relevant machine/detector findings. The review must answer:

- Does the render preserve the selected direction and first-viewport promise?
- Does it introduce material visible responsive, hierarchy, readability, or interaction concerns?
- Which material fixes are required, in priority order?
- What must not be diluted while fixing them?

The reviewer does not edit. Apply material fixes in one bounded pass, then capture final evidence. Machine checks establish readiness for review; only explicit user visual approval establishes subjective visual acceptance.
