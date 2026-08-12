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
| Read-only deterministic verification or package inspection | Session Goal may run without a new worktree | The objective is measurable and does not mutate source. |
| Writing work in a session already inside an isolated worktree | Session Goal may continue in that worktree | Isolation already exists; do not create a second worktree. |
| Writing work on the non-isolated checkout | Create a worktree before Goal | Automatic continuation must not mix with unrelated checkout changes. |
| Isolation is useful but scope or completion evidence is incomplete | Worktree only | Work can be isolated without granting automatic continuation. |
| Compare genuinely independent UI or architecture approaches | MultiRun with isolated runs | Separate worktrees prevent writers from changing the same checkout. |
| Release preparation | Goal may run only to `ready for release` | Publishing, deploying, tagging, merging, purchasing, and deletion still need approval. |

Focus Mode changes the composer, not the model, context, permissions, reasoning,
or autonomy. On Windows the default shortcut is `Ctrl+Shift+E`. Avoid it when
you need to keep consulting the transcript while writing.

## Adaptive Interview

Do not use a fixed question, option, or conversational-round count. Use the fast
path when the objective, affected behavior, constraints, and completion evidence
are already clear. When information is missing, interview by coherent topic and
expand only when an answer can change product scope, architecture, UI, data,
security, privacy, payment, cost, release, or verification.

One turn may contain several closely related questions. Do not combine unrelated
topics into a long form. After each round, summarize what is understood, what
remains open, and why the next topic matters. Normally compare a small group of
viable options, commonly two or three; group or offer more when hiding one would
remove a material trade-off.

Stop interviewing when the objective, users, in-scope/out-of-scope behavior,
constraints, unresolved decisions, recommended direction, and completion
evidence are decision-ready. Do not recommend a Goal while this interview is
still resolving a material decision.

## Session Goals

Use a Session Goal only when all conditions hold:

1. The end state is concrete and self-contained.
2. Completion evidence is named, such as a focused test, type check, build, or artifact inspection.
3. Product, UI, and material plan decisions are already resolved.
4. Multiple turns or repair attempts are likely.
5. Further in-scope work is safe without another approval.
6. The work does not include an unapproved external or destructive action.
7. Valid blocked conditions are named.
8. Writer ownership does not overlap another active lane.
9. Work that writes code is in an OpenChamber-managed worktree. Goal without a
   new worktree is limited to read-only/deterministic work or a session already
   inside an isolated worktree.

Do not use a Goal for interviewing, brainstorming, unresolved research, UI
direction selection, plan revision, or waiting for product, data, security,
privacy, payment, cost, credential, release, or external approval. Use a
worktree without a Goal when isolation helps but the finish line is not yet
decision-ready.

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

### Pause And Blocked Conditions

Pause the Goal and return to normal conversation when a new material product,
UI, dependency, service, public-contract, schema, migration, security, privacy,
payment, cost, credential, release-target, or external-action issue appears.
Report completed work, remaining work, the blocker, viable options, and one
recommendation. Never widen the Goal silently.

When a Goal is blocked, evaluating, or budget-limited, do not send duplicate
follow-ups, resume it, or increase its budget. Let the user choose whether to
resolve the blocker, narrow the objective, resume, or stop.

### Budget And Safe Limits

Set a budget large enough for the bounded objective, not for an open-ended project. Start with the default or a modest budget for one implementation and its focused checks. Pause and reassess when the task needs a material scope change, a third blind repair, a new external dependency, or approval for an external action.

The framework deliberately keeps `backgroundJobs.continueOnIdle` disabled in oh-my-opencode-slim. OpenChamber Session Goals are the only automatic parent session continuation controller. Do not activate slim idle continuation, send manual `continue` messages during Goal evaluation, or add another continuation plugin.

### Goal In Release

A Goal may prepare a release by:

- building or packaging;
- checking that the expected artifact exists and carries the intended version;
- installing or running it in a clean temporary environment;
- running the minimal smoke check;
- checking delivered contents;
- calculating and recording SHA-256;
- drafting release notes, known warnings, target, and rollback steps.

Its terminal state is `ready for release`. The Goal must stop before publish,
deploy, tag, push, merge, purchase, deletion, production mutation, or
post-release archive. Present the exact version, notes, target, warnings,
rollback plan, and external action for explicit user approval.

Run the exact approved external action outside the Goal boundary. Archive only
after that action succeeds, post-release smoke passes, and fresh strict OpenSpec
validation passes. Do not resume or widen a Goal to cross the release boundary.

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

Use `PRODUCT.md` for stable product intent, `DESIGN.md` for approved visual direction, and the active OpenSpec change for a bounded implementation's plan, tasks, evidence, and release record. The user supplies decisions in the session; the agent maintains these files and must not assign manual editing. Session notes may link to these artifacts but must not become a competing source of truth. Keep global prompts free of project-specific facts.

## Recommendation Format

After every completed workflow step or meaningful pause, give the user the next
slash command or session action and one short mode recommendation. Keep the
advice actionable:

```text
Bước tiếp theo: /opsx-apply add-status-endpoint
Cách làm phù hợp: Worktree + Goal.
Lý do: phần triển khai đã được duyệt, có nhiều bước và có kiểm tra hoàn thành rõ ràng.
```

For a Goal, follow with one suggested self-contained objective. For normal chat, do not add advice unless it changes the next action.
