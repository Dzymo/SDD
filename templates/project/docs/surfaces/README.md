# Surface Briefs

The agent creates and maintains one short Markdown file per material route,
screen, flow, or artifact after the user selects a UI direction in the session.
The user should not be asked to edit this file manually. Example:
`docs/surfaces/onboarding.md`.

## Authority

1. `PRODUCT.md` owns product truth, users, claims, outcomes, and constraints.
2. `DESIGN.md` owns durable system and visual decisions.
3. This surface brief owns only the approved, surface-specific composition,
   interactions, assets, and unresolved decisions.

A lower item cannot silently override a higher one. A task brief and code execute
these documents. For an established surface, preserve its existing direction.
For a new or material redesign, record the user's chosen direction before
production UI work; that choice is not final visual approval.

## Template

```markdown
# <Surface Name>

## Scope
- Route/flow:
- Audience and task:
- Primary action:
- Constraints:

## Approved Direction
- User approval source/date:
- Direction and visual language:
- First viewport and reading order:
- Required assets and interaction states:
- Must preserve:

## Open Decisions
-
```
