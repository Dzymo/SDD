# OpenChamber Operating Guide

## Purpose

OpenChamber is the control plane for projects, sessions, worktrees, Focus Mode,
Session Goals, and MultiRun. This guide makes those controls useful at the
right time without creating a second plan, worktree, or continuation system.

The Orchestrator may recommend a mode. You choose whether to turn it on.
Neither the framework nor a Session Goal may approve a release or an external,
destructive action.

## Choose The Smallest Mode

| Situation | Recommendation | Why |
|---|---|---|
| Short question or obvious small edit | Neither | Direct chat is cheaper and keeps attention on the request. |
| Long requirements, constraints, acceptance criteria, or structured feedback | Focus Mode | A larger structured composer makes the input easier to prepare. |
| Brainstorming, research, or an unresolved product decision | Normal chat; Focus Mode if the input is long | The finish line is not yet settled, so autonomous continuation would guess. |
| UI direction requires a user choice | Focus Mode for detailed feedback if useful; no Goal | The user must approve a direction before implementation continues. |
| Approved multi-step implementation with named checks | Worktree + Session Goal | Isolation avoids unrelated edits and the Goal can pursue a measurable finish line. |
| Reproducible bug likely to need more than one repair | Worktree + Session Goal | The bug, allowed scope, and regression check can form a safe bounded objective. |
| Isolation is useful but scope or completion evidence is incomplete | Worktree only | Work can be isolated without granting automatic continuation. |
| Compare genuinely independent UI or architecture approaches | MultiRun with isolated runs | Separate worktrees prevent writers from changing the same checkout. |
| Release preparation | Goal may run only to `ready for release` | Publishing, deploying, tagging, merging, purchasing, and deletion still need approval. |

Focus Mode changes the composer, not the model, context, permissions, reasoning,
or autonomy. On Windows the default shortcut is `Ctrl+Shift+E`. Avoid it when
you need to keep consulting the transcript while writing.

## Session Goals

Use a Session Goal only when all conditions hold:

1. The end state is concrete and self-contained.
2. Completion evidence is named, such as a focused test, type check, build, or artifact inspection.
3. Product, UI, and material plan decisions are already resolved.
4. Multiple turns or repair attempts are likely.
5. Further in-scope work is safe without another approval.
6. The work does not include an unapproved external or destructive action.

### Suggested Objective Template

Use this in the OpenChamber composer after you arm the target button:

```text
Objective: <observable completed outcome>.
Scope: change only <allowed files, capability, or worktree>.
Completion evidence: <exact focused command/check and expected result>.
Constraints: <approved design, dependency, safety, and no-scope-expansion rules>.
Blocked only when: <specific missing decision, unavailable credential, failing prerequisite, or material deviation>.
Do not: publish, deploy, tag, merge, purchase, delete, or change external state.
```

Example:

```text
Objective: Add the approved status endpoint in the current worktree.
Scope: only the endpoint, its focused tests, and the active OpenSpec change.
Completion evidence: `npm test -- status-endpoint` exits 0 and `npm run typecheck` exits 0.
Constraints: no new runtime dependency, no public API beyond the approved spec.
Blocked only when: the approved API contract is ambiguous or a required credential is unavailable.
Do not: deploy, merge, tag, or publish.
```

### Start, Watch, Pause, Resume

1. Arm the target button in the composer, write the self-contained objective, and send it. Confirm the Goal strip appears before leaving the application.
2. Watch the Goal strip for status, progress note, and token usage. `Evaluating` means OpenChamber is auditing the latest turn; do not send `continue` while it is evaluating.
3. Use Pause or Stop to halt the running turn and pause the loop. Normal chat remains available while paused.
4. Use Resume only after you have supplied the missing decision or corrected a blocked prerequisite. On an idle session, OpenChamber sends the continuation.
5. If the Goal reaches its budget, inspect progress before raising the budget and resuming. Do not raise it merely to continue an unclear task.

OpenChamber audits progress after turns and can mark a Goal complete, blocked, or budget reached. A Goal is one per session. It remains active while the OpenChamber desktop app or server process is running, even if the browser tab is closed.

### Budget And Safe Limits

Set a budget large enough for the bounded objective, not for an open-ended project. Start with the default or a modest budget for one implementation and its focused checks. Pause and reassess when the task needs a material scope change, a third blind repair, a new external dependency, or approval for an external action.

The framework deliberately keeps `backgroundJobs.continueOnIdle` disabled in oh-my-opencode-slim. OpenChamber Session Goals are the only automatic parent session continuation controller. Do not activate slim idle continuation, send manual `continue` messages during Goal evaluation, or add another continuation plugin.

## Worktrees And MultiRun

Create a worktree through OpenChamber when an implementation needs isolation from the main checkout or another writer. OpenChamber owns creation, branch selection, integration, and cleanup. Do not use slim's disabled worktree skill or a second worktree manager.

Use MultiRun only to compare independently valuable alternatives. Give each writer an isolated run and worktree, then review the sessions side by side and choose one direction. Do not use MultiRun to make several agents edit the same solution, retry a failure blindly, or run routine implementation in parallel.

## Folder And Project Memory Conventions

Keep durable facts in the project that owns them, not in a session transcript or global prompt:

```text
<project>/
  AGENTS.md                  # local tool, validation, and safety instructions
  PRODUCT.md                 # users, outcomes, vocabulary, and non-goals
  DESIGN.md                  # approved UI direction; only for meaningful UI
  openspec/
    specs/                   # current behavioral truth
    changes/<change>/        # proposal, design, tasks, verification, release
```

Use `PRODUCT.md` for stable product intent, `DESIGN.md` for approved visual direction, and the active OpenSpec change for a bounded implementation's plan, tasks, evidence, and release record. Session notes may link to these artifacts but must not become a competing source of truth. Keep global prompts free of project-specific facts.

## Recommendation Format

Keep advice to one short, actionable statement:

```text
OpenChamber recommendation: Worktree + Session Goal.
Reason: the approved implementation has named passing checks and needs several turns.
```

For a Goal, follow with one suggested self-contained objective. For normal chat, do not add advice unless it changes the next action.
