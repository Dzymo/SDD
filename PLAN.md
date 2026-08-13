# Personal OpenCode Workflow Framework - Final Implementation Plan

## 1. Document Status

This document is the implementation plan and decision record for a personal,
global OpenCode framework used through OpenChamber. The source repository and
reviewed source-release assets are public; the installed runtime and its
credentials, active configuration, state, and backups remain private.

- Owner: personal OpenCode installation
- Framework source workspace: `D:\Projects\SDD`
- Reference repositories: `D:\Projects\Docs`
- Target OpenCode config: `C:\Users\quang\.config\opencode`
- Target OpenChamber config: `C:\Users\quang\.config\openchamber`
- Distribution target: public GitHub source releases only; no npm package,
  marketplace extension, hosted service, or multi-user runtime
- Plan status: Phases 2 and 6 are source-complete. Phases 3 and 4 are active
  and runtime-verified. Phase 5 is active and was revalidated with its
  preflight and live structured-attachment OCR smoke on 2026-08-05; it still
  requires revalidation after a slim reinstall or update. Phases 7, 8, and 10
  were controlled-applied with per-file backups and runtime-verified on
  2026-08-05. Phase 9 is runtime-verified on 2026-08-05. Phase 11 is
  source-complete; its offline gate covers all 21 required scenarios but is a
  source-policy regression guard rather than live model-compliance evidence.
  The runtime records cited above are historical active-global evidence for
  the immutable candidate completed on 2026-08-08. A later read-only preflight
  on clean commit `e5bb0ed775a6c1340089a0f299c6699ac533bf20` passed CI and
  reported `NO_APPLY_REQUIRED`, all 14 managed targets `MATCH`, and Phase 5
  `MATCH`. This refreshes target/hash readiness but does not replace
  provider-backed research/OCR or manual disabled-MCP behavior evidence for a
  new full rollout certification. No global write was required.

Phase 12 global rollout is **complete** as of 2026-08-08 for immutable
candidate `b75043d6097d12ac52c5bbbc3224f316c3243961`. It recorded clean-source
and CI evidence, a no-drift diff preview, provider-backed research checks,
fresh/existing-project smoke tests, a file-level rollback/reapply drill, and
sanitized active-version/checksum evidence. See `PHASE-12-GLOBAL-ROLLOUT.md`
for the completion record and its stated limitations.

Current evidence is tracked in four distinct classes:

- Source/CI: source contracts and Windows CI for the exact candidate SHA.
- Isolated managed runtime: plugin initialization and runtime contracts under a
  temporary redirected home.
- Active target/hash readiness: read-only comparison of the actual managed
  targets and Phase 5 package identity.
- Provider/manual behavior: provider-backed research/OCR and temporary
  disabled-MCP behavior checks, required only by the applicable rollout gate.

This file is the source of truth for framework implementation. If a later
decision changes the architecture, model routing, safety boundary, or workflow,
update this file before changing the global installation.

## 2. Goals

Build a global personal framework that guides work from an initial idea to a
verified and releasable result while keeping the process understandable for a
non-coder solo developer.

The framework must:

1. Reuse and adapt proven mechanisms from the repositories in
   `D:\Projects\Docs` before creating new components.
2. Automate research, specification, planning, task creation, implementation,
   verification, packaging, and release preparation.
3. Involve the user only for product intent, material UI decisions, material
   plan changes, destructive or costly actions, and final release approval.
4. Use Context7 for every external API or dependency decision.
5. Use real commands and observable evidence instead of agent claims as proof.
6. Keep prompts, agents, artifacts, and gates proportionate to the task.
7. Prevent GPT-5.6 Sol, the orchestrator, and imported skills from expanding a
   bounded task into unnecessary research, subagents, reviews, tests, or
   abstractions.
8. Proactively advise the user when OpenChamber Focus Mode, Session Goals,
   worktrees, or neither are appropriate.

## 3. Non-Goals

The first version will not:

- become an npm/marketplace package, hosted service, or multi-user product;
- modify OpenChamber source code;
- create a new general-purpose workflow engine;
- install OpenSpec and Spec Kit as competing workflow systems;
- auto-merge, auto-deploy, auto-publish, auto-purchase, or auto-delete work;
- enable Council, Deepwork, MultiRun, scheduled autonomy, or whole-repository
  audits by default;
- require TDD, a worktree, a design document, or an independent review for
  every change;
- build a database-backed evidence ledger before Markdown evidence proves
  insufficient;
- copy all sample-repository prompts or plugins into the global installation;
- treat a large context window or high reasoning effort as a substitute for a
  clear scope and definition of done.

## 4. Architecture

```text
OpenChamber
  Control plane: projects, sessions, Focus Mode, Plans, Goals, worktrees,
  notifications, previews, model selection
        |
        v
oh-my-opencode-slim Orchestrator
  Routing, bounded delegation, user guidance, reconciliation, risk decisions
        |
        +--> Librarian + Context7: external API/dependency evidence
        +--> Explorer + CodeGraph/Grep/Read: local code evidence
        +--> Designer/Fixer: bounded implementation
        +--> Observer: optional media isolation
        +--> Oracle: difficult judgment and independent review
        |
        v
OpenSpec per project
  Proposal, specifications, design/plan, tasks, verification, release history
        |
        v
Real validation
  Tests, lint, type checks, builds, browser checks, package smoke tests
        |
        v
User release approval
  Publish/deploy/tag/merge only after explicit approval
```

### 4.1 Ownership Boundaries

| Concern | Single owner |
|---|---|
| User interface and session control | OpenChamber |
| Automatic cross-turn continuation | OpenChamber Session Goals |
| Worktree creation and cleanup | OpenChamber |
| Agent routing and specialist prompts | oh-my-opencode-slim |
| Change intent and project history | OpenSpec |
| External API/dependency evidence | Context7 through Librarian |
| Local structural evidence | CodeGraph plus Explorer |
| Exact local text/config evidence | Glob, Grep, and Read |
| Runtime correctness | Project-native commands |
| Final release authorization | User |

The framework must not create a second continuation controller, worktree
manager, plan source of truth, or release authority.

## 5. Global and Project-Local Split

The framework is installed globally, but project facts remain project-local.

### 5.1 Global Assets

Global assets may include:

- OpenCode provider and model metadata overlays;
- Context7 and CodeGraph MCP configuration;
- oh-my-opencode-slim plugin configuration and prompt overrides;
- global workflow skills and commands;
- model-routing policy;
- source-first research policy;
- anti-overthinking and anti-overengineering policy;
- Focus Mode, Session Goal, and worktree advisory rules;
- global permission and release safety boundaries;
- reusable project bootstrap command or script.

### 5.2 Project-Local Assets

Each participating project may contain:

```text
AGENTS.md
PRODUCT.md
DESIGN.md                  # only when the project has meaningful UI
openspec/
  specs/
  changes/
```

Project-local content includes:

- product purpose, users, terminology, and non-goals;
- approved UI direction and design-system constraints;
- OpenSpec proposals and behavioral specifications;
- project-specific build, test, package, and release commands;
- dependency versions and Context7 evidence;
- verification and release records.

Global prompts must not contain one project's product assumptions.

## 6. Source-First Reuse Policy

Before creating an important framework component, the agent must inspect the
sample repositories and record provenance.

Required decision fields:

| Field | Requirement |
|---|---|
| Need | Problem the component solves |
| Repositories inspected | Repositories and exact paths examined |
| Candidate mechanism | Existing skill, prompt, schema, hook, test, or code |
| Decision | `reuse`, `adapt`, or `new` |
| Reason | Why the selected option is smallest and suitable |
| Rejection reason | Why other candidates were not selected |
| Verification | How the integrated component will be tested |

Rules:

1. Search `D:\Projects\Docs` before designing a replacement.
2. Use CodeGraph for architecture and relationships when the repository is
   indexed and healthy.
3. Use Grep and Read for exact text, configuration, generated files, stale
   files, or unindexed content.
4. Use Context7 for every external API or dependency.
5. Create new code only when no suitable component exists or adaptation would
   cost more and add more risk than a small new component.
6. A reviewer must reject a framework change that introduces a major component
   without source provenance.

## 7. Repository Adoption Decisions

| Repository | Adopt | Adapt | Do not adopt |
|---|---|---|---|
| OpenSpec | Change packages, delta specs, validation, archive, OpenCode commands | Add research, verification, packaging, and release evidence | File existence as quality proof; validation bypass |
| Spec Kit | Independent user stories, clarification taxonomy, task traceability, consistency review | Condense into OpenSpec artifacts | Full CLI, workflow engine, extension catalogs, parallel source of truth |
| oh-my-opencode-slim | Orchestrator and specialist roles, prompt layering, model routing, job reconciliation | Leaner routing, explicit permissions, personal model preset | Default worktree skill, idle continuation, multiplexer, companion, default Council |
| OpenChamber | Focus Mode, Session Goals, Plans, notes, worktrees, MultiRun when justified | Add agent advice and conventions | Second workflow state engine |
| Superpowers | Task briefs, root-cause debugging, focused verification, review-package ideas | Risk-based TDD and one bounded review loop | Global bootstrap, 1% skill rule, mandatory brainstorming, microtasks, per-task agents/reviews |
| Ponytail | Reuse-first ladder, safety carve-outs, complexity-only review | Compact role-specific policy | Global every-turn injection and whole-repo audit by default |
| Context7 | Resolve-then-query, version-aware official docs, OAuth MCP | Evidence table and fail-soft states | Silent fallback to memory; proprietary code in queries |
| CodeGraph | Read-only structural exploration, impact analysis, staleness signals | Critical-work sync/status preflight | Treating graph results as runtime proof |
| Impeccable | Product/design context, surface brief, detector, critique/audit/polish | Integrate checks into project workflow | Full design ceremony for mechanical fixes |
| Open Design | Structured questions, direction cards, preview and annotation patterns | Learn UX patterns only | Current OpenCode Design Jury and synthetic critique score as gates |
| Taste Skill | Selected anti-generic UI heuristics | Contextualize absolute style rules | Universal aesthetic authority |
| i-have-adhd | Action-first communication, bounded next action, three-failure assumption check | Diagnosis-neutral focus-friendly style | Second goal/progress system |

## 8. Model Routing Baseline

Model routing uses the active CLIProxy provider selected by Phase 1. The retired
CPA GUI routes are historical provenance only and must not be reintroduced as a
framework dependency or inferred from model-name suffixes.

| Agent | Baseline model | Mode/variant | Role |
|---|---|---|---|
| Orchestrator | `cliproxy/gpt-5.6-terra` | Default `medium`; `high` is the named fallback | Routine orchestration and decisions |
| Oracle | `cliproxy/gpt-5.6-sol` | Default `medium`; `high` is the named fallback | Architecture, difficult debugging, material risk, independent review |
| Librarian | `minimax-coding-plan/MiniMax-M3` | `none` | Context7 and external source retrieval |
| Explorer | `minimax-coding-plan/MiniMax-M3` | `none` | Local search and code navigation |
| Designer | `minimax-coding-plan/MiniMax-M3` | `thinking` | Approved UI direction, implementation, and visual review |
| Fixer | `minimax-coding-plan/MiniMax-M3` | `none` | Bounded implementation and routine test work |
| Observer | `minimax-coding-plan/MiniMax-M3` | `none` | Optional image/video analysis and context isolation |
| OpenChamber Small Model | To be selected after benchmark | Low-cost, reliable JSON output | Goal audit and utility calls |

### 8.1 Model Challengers

| Role | Challenger |
|---|---|
| Orchestrator | Terra High |
| Oracle | Sol High |
| Librarian | M3 `thinking` for conflicting or multi-source research |
| Explorer | M3 `thinking` for difficult cross-repository or structural search |
| Designer | Terra or Sol after direct multimedia is verified |
| Fixer | M3 `thinking` for difficult bounded tasks |

### 8.2 Why M3 `none` for Librarian and Explorer

- It has a verified 1,000,000-token context and 128,000-token output limit.
- Tool calling is exposed by the active provider.
- Reasoning can be explicitly disabled for routine retrieval.
- M3 `thinking` is unnecessary for ordinary lookup and search.
- Architecture interpretation is escalated to Oracle rather than turning a
  search specialist into an open-ended reasoner.

Use M3 `thinking` only when a normal `none` pass leaves material evidence
missing or conflicting. A failed query caused by invalid input, an unavailable
tool, permissions, or an indexing problem must be corrected directly rather
than retried with more reasoning.

### 8.3 Effort Policy

| Level | Allowed use |
|---|---|
| `none` or `low` | Retrieval, classification, local search, mechanical execution |
| `medium` | Normal orchestration, planning, research synthesis, ordinary review |
| `high` | Difficult debugging, security, data integrity, concurrency, migration, cross-system architecture |
| `xhigh` | One scoped quality-first task only when local evals show a meaningful benefit |
| `max` | Disabled from the default global framework |

Rules:

1. Do not use Sol XHigh as a default agent model.
2. Do not increase effort before checking scope, success criteria, tool routing,
   prompt conflict, and stopping conditions.
3. Escalation is per task, not a permanent session-wide upgrade.
4. XHigh work must use a fresh or narrowly scoped session, one clear question,
   explicit evidence, a findings cap, and no unapproved subagent fan-out.
5. CPA GUI routes are retired from framework selection. Do not infer their old
   suffixes or restore that provider merely to benchmark it.

## 9. Anti-Overthinking and Anti-Overengineering Policy

This policy is global and outranks imported workflow habits unless a named
safety or release rule requires broader work.

### 9.1 Core Rules

1. Default to the smallest workflow that can establish the requested outcome.
2. For bounded work with known files and clear acceptance criteria, execute
   directly. Do not delegate merely because work has multiple steps or files.
3. Before using tools, identify the stopping condition.
4. Start retrieval with one focused batch. Use a second batch only if required
   evidence is missing, conflicting, stale, or suspiciously narrow.
5. Do not search again only to increase confidence, improve wording, collect
   optional examples, or investigate hypothetical edge cases outside scope.
6. Use at most two concurrent subagents. Each must own a substantial,
   independent lane with non-overlapping write scope.
7. Do not create one agent per file, folder, task, test, or review category.
8. Perform one self-check. Request independent review only for a named material
   risk or a sufficiently large and difficult-to-inspect change.
9. Use one consolidated remediation pass and at most one scoped re-review.
10. After two unsuccessful repair attempts, stop changing code and re-evaluate
    the shared assumption or root cause.
11. Run the narrowest meaningful validation after the last relevant change.
12. Do not rerun unchanged evidence because a new message, phase, or task began.
13. Do not run a full project suite by habit; broaden only for integration risk,
    shared behavior, release policy, or a focused failure.
14. Do not introduce dependencies, abstractions, services, agents, gates, or
    artifacts outside the approved plan without a material-change decision.
15. Stop when acceptance criteria pass. Record non-blocking improvements as
    follow-ups rather than expanding the task.

### 9.2 Prompt Language to Remove

Do not add broad instructions such as:

- `Be extremely thorough.`
- `Consider every edge case.`
- `Do not stop at the first plausible explanation.`
- `Review and revise repeatedly.`
- `Keep investigating until fully confident.`
- `Be exhaustive.`
- `Make it bulletproof.`
- `Use a subagent for every task.`

Replace them with a concrete scope, evidence requirement, retry cap, and stop
condition.

### 9.3 Session Boundaries

Use new sessions to prevent stale reasoning and accumulated instructions from
anchoring later phases.

| Transition | Default action |
|---|---|
| Idea to specification | Same session is acceptable |
| Specification to implementation | New session, preferably in a worktree |
| Implementation to independent review | Fresh reviewer context with plan, diff, and evidence only |
| Review to repair | Send only actionable findings and relevant paths |
| Verification to release preparation | New release-preparation session when useful |

## 10. Required Prompt and Skill Changes

### 10.1 Orchestrator

Replace the default delegation threshold with:

```text
Default to direct execution for bounded work with known files and a clear
solution. Delegate only when a specialist provides a capability the current
lane lacks, or when a substantial independent lane justifies coordination cost.
Do not delegate solely because work is non-trivial, multi-step, or multi-file.
Use no more than two concurrent subagents.
```

Retain slim's existing narrow-verification rules:

- choose the minimum meaningful evidence;
- start with the narrowest check;
- do not run project-wide checks by habit;
- request independent review only when its risk reduction justifies cost.

The final implementation must determine whether a prompt replacement is safer
than an append. Do not add contradictory append-only language to a prompt that
continues to mandate delegation.

### 10.2 Explorer

Replace `thorough` and `exhaustive` wording with:

```text
Start with one focused search batch. Stop when the requested symbol, file,
ownership boundary, or relationship is established with path and line evidence.
Run a second batch only if the first result is insufficient or conflicting.
Do not inventory unrelated files and do not broaden into architecture review.
```

### 10.3 Librarian

Require:

- Context7 attempt for every external API/dependency decision;
- one concept per query;
- selected library ID and version;
- citations tied to supported claims;
- official/community distinction;
- at most one fallback retrieval round unless evidence conflicts;
- escalation to Oracle for architectural judgment.

### 10.4 Deepwork

Deepwork remains explicit and high-cost.

Change review policy to:

- one final Oracle review by default;
- add a phase review only for security, irreversible migration, data integrity,
  public contract, or a load-bearing architecture boundary;
- maximum two Oracle reviews for the entire task;
- one consolidated remediation and at most one scoped re-review.

### 10.5 Verification Planning

Use only when:

- the evidence path is genuinely unclear;
- a false conclusion has material consequences;
- the change crosses security, persistence, concurrency, external-service, or
  public-contract boundaries;
- existing checks provide indirect or ambiguous evidence.

Routine changes with a clear focused check must not invoke this skill. Consider
at most two evidence paths and stop when one direct, proportionate path exists.

### 10.6 Superpowers Material

Do not install the Superpowers plugin or global bootstrap.

Only adapt:

- bounded task briefs;
- root-cause debugging after the fast path fails;
- evidence before completion claims;
- focused independent review for material risk.

Do not import:

- the 1% skill invocation rule;
- mandatory brainstorming;
- mandatory TDD;
- 2-5 minute task granularity;
- fresh subagent per task;
- review after every task;
- five repair/re-review rounds;
- `bulletproof` or indefinite convergence language.

### 10.7 OpenSpec Explore

Keep exploration adaptive and bounded by relevance rather than fixed counts:

- use the fast path when the objective, affected behavior, constraints, and
  completion evidence are already clear;
- interview by coherent topic and expand only when an answer can change product
  scope, architecture, UI, data, security, cost, release, or verification;
- normally compare a small group of viable options, commonly two or three, but
  group or reveal more when omitting one would hide a material trade-off;
- after each round, summarize what is understood, what remains open, and why the
  next topic matters;
- stop when the objective, users, in-scope/out-of-scope behavior, constraints,
  unresolved decisions, recommended direction, and completion evidence are
  decision-ready;
- do not continue solely to improve confidence or wording.

## 11. Research and Evidence Protocol

### 11.1 Request Classification

Classify evidence needs as:

- `external-api`
- `local-code-structure`
- `exact-local-text`
- `runtime-correctness`
- `mixed`

### 11.2 Context7 Protocol

For external APIs and dependencies:

1. Resolve the official library ID.
2. Select the relevant version.
3. Query one concept at a time.
4. Record library ID, version, query, retrieval date, and result.
5. Use only retrieved evidence for API claims.
6. Do not silently fall back to model memory.

Fail-soft behavior:

| Condition | Behavior |
|---|---|
| Low-risk API lookup fails | Record failure, use official docs, label fallback |
| Auth, payment, crypto, destructive cloud, or migration evidence fails | Block that decision only |
| Local work is independent of failed API lookup | Continue local work |
| Requested version is absent | Check official release docs and record discrepancy |

Never place proprietary code, credentials, customer data, or secrets in a
Context7 query.

### 11.3 CodeGraph Protocol

Use CodeGraph for:

- architecture and ownership;
- callers, callees, and execution flow;
- impact analysis;
- affected test leads;
- cross-file relationships.

Use Grep and Read for:

- exact strings and error messages;
- JSON, YAML, TOML, environment, and generated files;
- stale or unindexed files;
- documentation;
- files skipped by CodeGraph.

For critical changes, run CodeGraph sync/status preflight. Treat partial,
indexing, stale, degraded, or unresolved-reference states as advisory evidence
only.

### 11.4 Minimum Evidence Table

Use Markdown first:

```markdown
| Claim | Source/tool | Version/path | Evidence | Status |
|---|---|---|---|---|
```

Build a structured JSON ledger only if later CI automation needs it.

## 12. Project Workflow

### 12.1 Artifact Chain

```text
idea/context
  -> proposal.md
  -> research.md when needed
  -> specs/<capability>/spec.md
  -> design.md
  -> tasks.md
  -> implementation and tests
  -> verification.md
  -> package artifact
  -> release.md
  -> OpenSpec archive
```

Use OpenSpec as the backbone. Keep its default artifact graph for the initial
version; store optional evidence files alongside it before considering a custom
schema.

The session is the user's only authoring surface. Agents use an adaptive
interview: they ask only about topics that can change the decision, may group
closely related questions, summarize between rounds, and stop when the work is
decision-ready. Options are presented in a manageable comparison rather than a
fixed count; the user may delegate reversible low-risk technical defaults, but
product intent, privacy, security, payment, destructive work, irreversible
migration, release targets, and external actions remain explicit decisions.
Agents create or update `PRODUCT.md`, `DESIGN.md`, `PACKAGE.md`, surface briefs,
OpenSpec artifacts, verification, and release records themselves. The user is
never assigned manual file editing. After each workflow step or meaningful
pause, the agent names the next slash command or session action and recommends
Focus Mode, Session Goal, worktree, MultiRun, or neither with one short reason.

### 12.2 Stage Rules

| Stage | Automation | User gate | Required output |
|---|---|---|---|
| Idea | Normalize problem, user, outcome, constraints | User supplies or corrects intent | Idea brief or proposal draft |
| Research | Context7, CodeGraph, sample-repo inspection | Only unresolved product facts | Research evidence when needed |
| Specification | Proposal, behavioral requirements, scenarios | Only material ambiguity | Valid OpenSpec proposal/spec |
| Plan | Technical decisions, verification, package, rollback | One combined plan approval | `design.md` |
| Tasks | IDs, paths, dependencies, acceptance checks | None | `tasks.md` |
| Implementation | Worktree, bounded worker tasks, focused checks | Only material deviation | Code and task status |
| Verification | Project commands and independent judgment | Subjective visual check if needed | `verification.md` |
| Packaging | Build, clean install/run, checksum | None | Package artifact |
| Release | Version, notes, target, rollback | Mandatory approval | `release.md` |
| Archive | Merge specs and archive change | None after release | OpenSpec archive |

### 12.3 Material Deviation

Pause for a user decision when implementation would:

- add an unapproved runtime dependency or external service;
- change public API, schema, data lifecycle, or migration strategy;
- alter auth, payment, privacy, or security boundaries;
- change the approved UI direction;
- materially increase scope, operating cost, or delivery time;
- change the release target or rollback plan;
- perform a destructive or irreversible action.

Do not pause for routine inspection, focused tests, local refactors, regression
tests, or repairs within the approved plan.

## 13. Task Execution Loop

```text
Orchestrator defines bounded task brief
  -> Fixer or Designer implements
  -> Worker runs focused validation and reports evidence
  -> Orchestrator reconciles result
  -> Oracle reviews only when named material risk justifies it
  -> One consolidated repair pass
  -> At most one scoped re-review
  -> Final project-level verification
```

### 13.1 Task Brief Contract

Each delegated write task must include:

- task ID;
- observable outcome;
- allowed files or ownership boundary;
- relevant interfaces and invariants;
- acceptance criteria;
- focused validation command or evidence;
- forbidden scope changes;
- Context7 evidence when an API/dependency is involved;
- expected final report.

Do not give a worker the entire conversation when a brief and referenced files
are sufficient.

### 13.2 Repair Policy

| Attempt | Action |
|---|---|
| 1 | Worker repairs exact findings and runs focused validation |
| 2 | Worker continues only if root cause is understood |
| 3 | Stop blind repair; Oracle or Orchestrator re-evaluates the assumption/root cause |

Ask the user only if the corrected approach requires a material deviation.

### 13.3 Risk-Based TDD

Require RED-GREEN for:

- regression bugs;
- public behavior and APIs;
- parsers and serializers;
- state transitions;
- auth, validation, security, money, and data integrity;
- migrations and concurrency;
- non-trivial business logic.

Do not fabricate a failing test for:

- documentation;
- simple configuration;
- generated files;
- mechanical wiring or renames;
- small CSS changes;
- obvious wrappers.

All changes still require proportionate verification.

## 14. OpenChamber Advisory Policy

The Orchestrator should proactively advise, but never silently activate, Focus
Mode, Session Goals, worktrees, or MultiRun.

### 14.1 Recommendation Matrix

| Situation | Recommendation |
|---|---|
| Short question or obvious small change | Neither Focus nor Goal |
| Long requirements, constraints, or structured feedback | Focus Mode |
| Brainstorming, research, or unresolved decisions | Normal chat; Focus if useful; no Goal |
| Approved multi-step implementation with verifiable finish line | Worktree plus Session Goal |
| Reproducible bug with clear done criteria | Worktree plus Session Goal when multiple attempts are likely |
| Read-only deterministic verification or package inspection | Session Goal may run without a new worktree |
| Writing work in a session already inside an isolated worktree | Session Goal may continue in that worktree |
| Writing work on the current non-isolated checkout | Create a worktree before recommending a Goal |
| UI direction still needs user choice | Focus for feedback; no Goal yet |
| Improve an existing saved plan | Normal session; do not use current `Run as goal` path |
| Prepare release artifacts | Goal may run only to `ready for release` |
| Publish, deploy, tag, merge, or purchase | Stop and request approval |
| Compare independent UI/architecture alternatives | MultiRun with separate worktrees, only when comparison value justifies cost |

### 14.2 Focus Mode Advice

Recommend Focus Mode when:

- the prompt is longer than the normal composer;
- the user is writing requirements, acceptance criteria, constraints, or UI
  feedback;
- the objective needs headings and careful structure.

Do not imply that Focus Mode changes the model, reasoning, context, permissions,
or autonomy. On Windows, the default shortcut is `Ctrl+Shift+E`.

Do not recommend it when the user needs to continuously refer back to the
transcript while writing.

### 14.3 Session Goal Advice

Recommend a Session Goal only when all are true:

1. The end state is concrete.
2. Completion evidence is named.
3. Important user decisions are resolved.
4. Multiple turns or attempts are likely.
5. Safe in-scope work can continue without repeated approval.
6. The objective does not include an unapproved external or destructive action.
7. Valid blocked conditions are named.
8. Writer ownership does not overlap another active lane.
9. Work that writes code is in an OpenChamber-managed worktree; Goal without a
   new worktree is limited to read-only/deterministic work or a session already
   running in an isolated worktree.

When recommending a Goal, provide:

- objective;
- completion criteria;
- constraints;
- valid blocked conditions;
- worktree recommendation;
- token-budget recommendation.

Do not recommend a Goal while the agent is interviewing, brainstorming,
researching an unresolved decision, selecting a UI direction, changing a plan,
or waiting for product, data, security, cost, credential, release, or external
approval. Use a worktree without a Goal when isolation is useful but the finish
line is not decision-ready.

During a Goal, pause and return to normal conversation when a new material
decision, dependency, service, public contract, schema, migration, security,
privacy, payment, UI-direction, cost, release-target, or external-action issue
appears. Report completed work, the blocker, options, and a recommendation. Do
not silently widen the objective.

For release preparation, a Goal may build/package, inspect the artifact, run a
clean-environment smoke, calculate checksums, prepare release notes, collect
warnings, and draft rollback steps. Its terminal state is `ready for release`.
It must stop before publish, deploy, tag, push, merge, purchase, production
mutation, or post-release archive. After the user explicitly approves the exact
version, notes, target, warnings, rollback plan, and external action, that exact
action runs outside the Goal boundary. Release-applicable archive follows only
after success, post-release smoke, and fresh strict validation. A genuine
no-external-release change may archive only after focused verification, strict
validation, and an explicit `releaseApplicable: false` record with a reason.

The agent must not:

- arm a Goal without the user;
- raise a budget;
- resume a blocked or budget-limited Goal automatically;
- enable permission auto-accept;
- turn `/craft-goal` or planning into an active Goal;
- send `continue` while the Goal is evaluating;
- change Goal scope through ordinary messages without pausing first.

When a Goal is blocked, evaluating, or budget-limited, do not duplicate a
follow-up, resume it, or increase its budget. Summarize completed and remaining
work, explain the blocker in plain language, and let the user choose whether to
resolve, narrow, resume, or stop.

After composer activation, remind the user to confirm that the Goal strip
appears before leaving the application.

### 14.4 Advice Format

Keep advice brief and issue it only when it changes the recommended next action.

```text
Cách làm phù hợp: Worktree + Goal.
Lý do: kế hoạch đã được duyệt, có điểm kết thúc kiểm chứng được và cần nhiều lượt.
```

## 15. UI Workflow

For a new UI or material redesign:

1. Load `PRODUCT.md`, `DESIGN.md`, and any surface brief.
2. Use Focus Mode for the user's long design input when useful.
3. Produce up to three structurally distinct directions.
4. Ask the user to select or explicitly combine directions.
5. Persist the approved direction as a surface brief.
6. Use Designer for production-code implementation.
7. Run build, browser, responsive, accessibility, console/network, and
   Impeccable detector checks as applicable.
8. Use a fresh visual reviewer with screenshots and the approved brief.
9. Ask for final subjective visual approval before release when needed.

For small UI maintenance, skip direction exploration and use the existing
design system plus a compact surface brief.

Do not use Open Design's current synthetic critique score or OpenCode Design
Jury as a ship gate.

## 16. Observer and Multimedia Policy

Current effective model metadata:

| Route | Image | Video | PDF | Attachment |
|---|---:|---:|---:|---:|
| `cpa-gui/gpt-5.6-*` | No | No | No | No |
| `minimax-coding-plan/MiniMax-M3` | Yes | Yes | No | Yes |

The underlying GPT model may support media, but OpenCode currently treats the
CPA GUI entries as text-only because model metadata does not declare media
capabilities.

Active policy:

- enable Observer with M3 `none` under explicit read-only permissions;
- use `image_routing: auto` while the GPT route remains text-only, then call
  `observer_attachment` to create a child session and send M3 a structured
  image `FilePart`;
- use Observer for screenshots, diagrams, OCR, and image comparison;
- do not claim PDF support through M3;
- use OpenChamber text extraction, selected-page image conversion, or another
  verified PDF-capable route for PDFs.

Observer permissions must default deny and allow only read-oriented tools.
Explicitly deny shell mutation, editing, patching, delegation, todo, and user
question tools.

`scripts\Test-ObserverAttachment.ps1` is the activation evidence. It creates
an image with a unique visible code, verifies the child session result, and
requires M3 to return that code. Rerun it after a plugin reinstall or update.

After direct GPT multimedia metadata and transport are verified, benchmark:

- Observer auto-routing;
- direct GPT media;
- direct media with manual Observer fallback.

Keep Observer only if context isolation, OCR quality, automation, or cost
justifies the extra model call.

## 17. Verification and Release Evidence

### 17.1 Verification Record

Each significant change should produce:

```markdown
# Verification

## Source
- Change:
- Commit:
- Date:

## Specification
- OpenSpec strict validation:

## Project Checks
| Check | Command | Result |
|---|---|---|

## Requirement Coverage
| Requirement | Test or evidence | Result |
|---|---|---|

## Remaining Uncertainty
```

### 17.2 Package Gate

Require:

- package/build command succeeds;
- expected artifact exists;
- artifact installs or runs in a clean temporary environment;
- embedded version matches intended version;
- no secrets or development-only files are included;
- SHA-256 checksum is recorded;
- minimal smoke test passes.

### 17.3 Release Gate

Require explicit user approval for:

- version;
- release notes;
- target/environment;
- known warnings;
- rollback plan;
- tag, push, publish, deploy, merge, or other external write.

After release succeeds, record the result and run normal OpenSpec archive without
validation bypass.

## 18. Global Configuration Safety

The current `C:\Users\quang\.config\opencode\opencode.json` is managed by CPA
GUI. Its sidecar state and backup indicate that direct edits may be overwritten.

Rules:

1. Determine config ownership before writing.
2. Prefer a supported global overlay or CPA GUI-compatible change path.
3. Back up every affected file before the first change.
4. Preserve JSONC comments and unrelated settings.
5. Use schema validation and `opencode debug config` after changes.
6. Never copy OpenChamber's entire `settings.json`; it contains local private
   keys and personal state.
7. Do not commit credentials, relay keys, auth files, or local identifiers to
   `D:\Projects\SDD`.
8. Restart OpenCode/OpenChamber after config, plugin, MCP, agent, command, or
   skill changes when required.

## 19. Implementation Phases

### Phase 0 - Baseline and Ownership

Objective: establish a safe and reproducible starting point.

Status: completed on 2026-08-02. See `PHASE-0-BASELINE.md` for sanitized
runtime evidence, ownership boundaries, checksums, exclusions, and file-level
backup/rollback procedure. No global configuration was modified. Phase 1 must
benchmark the managed OpenChamber route and must not assume CPA GUI effort
mapping from model-name suffixes.

Tasks:

- inventory effective OpenCode and OpenChamber versions;
- identify managed versus external OpenCode mode;
- identify which process owns `opencode.json`;
- inventory plugin, skill, agent, MCP, model, and permission state;
- record exact CPA GUI and MiniMax model metadata;
- identify secret-bearing files that must never enter framework backups;
- define backup and rollback commands;
- create a baseline report in `D:\Projects\SDD`.

Evidence:

- `opencode --version`;
- `opencode debug config`;
- `opencode models --verbose` for relevant providers;
- `opencode agent list`;
- OpenChamber managed/external mode evidence;
- checksums of files before modification, excluding secret content from reports.

Complete when:

- every planned config write has one known owner and rollback path;
- no model capability or effort mapping remains assumed.

### Phase 1 - Model and Prompt Benchmarks

Objective: select models and effort by evidence.

Status: completed on 2026-08-02. `PHASE-1-MODEL-BENCHMARK.md` records passing
M3 `none`/`thinking` and active CLIProxy Terra/Sol default/`high` routing smoke
results. The original CPA GUI conditions are retained separately as invalid
route provenance because the provider had been replaced before they ran.

Librarian matrix:

- M3 `none`;
- M3 `thinking`.

Explorer matrix:

- M3 `none`;
- M3 `thinking`.

Orchestrator matrix:

- Terra effective Medium/default;
- Terra High.

Oracle matrix:

- Sol effective Medium/default;
- Sol High.

Metrics:

- task correctness;
- citation and version accuracy;
- file and line recall;
- invalid or redundant tool calls;
- number of subagents;
- scope expansion;
- repeated search/review/test behavior;
- latency;
- token/quota use where observable;
- stop-condition compliance;
- user questions that were not necessary.

Do not benchmark XHigh until Medium/High fails on a real difficult case.

Complete when:

- one baseline and one fallback are selected for every active agent;
- decisions are recorded with raw task results and limitations.

### Phase 2 - Private Framework Skeleton

Objective: create the private source layout in `D:\Projects\SDD`.

Status: completed on 2026-08-02 and verified on 2026-08-03. The skeleton,
lifecycle documentation, and read-only verifier are present. No global OpenCode
or OpenChamber configuration was copied, generated, or applied. The bounded
source-level evidence is recorded in `PHASE-2-FRAMEWORK-SKELETON.md`.

Expected layout:

```text
D:\Projects\SDD\
  PLAN.md
  README.md
  docs\
    architecture.md
    decisions.md
    operations.md
    model-evals.md
    rollback.md
  config\
    opencode\
    oh-my-opencode-slim\
  prompts\
  skills\
  commands\
  templates\
    project\
    openspec\
  scripts\
  evals\
  fixtures\
```

Keep only assets needed for the personal installation. Do not build public
packaging or marketplace metadata.

Complete when:

- the repository documents how global files are generated, applied, checked,
  and rolled back;
- no secrets are present.

### Phase 3 - Research Layer

Objective: make current external and local evidence available globally.

Status: source-complete; the historic 2026-08-03 runtime record is retained
for provenance. The managed OpenCode runtime uses the reviewed Context7 OAuth
MCP and CodeGraph local MCP; Librarian returned versioned Context7 evidence,
Explorer returned CodeGraph path/line evidence, and disabled-MCP fixtures
established explicit fail-soft behavior. The runtime verifier now separates
config inspection from the prompt-based behavioral assertion; live model
behavior under the disabled state is a manual gate, not a runtime-verified
claim. The runtime must be re-run after any change to the verifier, the
reviewed MCP source, the CodeGraph install, or the OpenCode version. The
re-run is a required residual gate and has not been performed in this
update. See `PHASE-3-RESEARCH-LAYER.md`.

Tasks:

- install Context7 through its supported OpenCode OAuth setup or equivalent
  reviewed configuration;
- install CodeGraph MCP locally;
- add hidden references to selected repositories under `D:\Projects\Docs`;
- create the source-first research policy skill;
- add Context7 fail-soft and CodeGraph staleness behavior;
- enforce explicit read-only permissions for research agents.

Complete when:

- Librarian successfully resolves and queries a versioned library;
- Explorer/CodeGraph returns exact local paths and line evidence;
- failure fixtures demonstrate correct fallback without silent memory use.

### Phase 4 - Agent Layer

Objective: activate the lean personal orchestration preset.

Status: source-complete; historic 2026-08-02 runtime verification retained
for provenance. The pinned `oh-my-opencode-slim@2.2.8` registration,
`sdd-personal` preset, targeted prompt replacements, and runtime/source
verifiers are recorded in `docs/agent-layer.md` and
`PHASE-4-AGENT-LAYER.md`. The standalone managed CLI passed the runtime
verifier on 2026-08-02 (before Observer was added to the verifier), and the
user confirmed Orchestrator, Explorer, Librarian, Oracle, Designer, and Fixer
appear in OpenChamber after restart. Council remains disabled. Observer was
originally disabled at the Phase 4 record date and was later enabled by the
verified Phase 5 structured attachment handoff; the runtime verifier now
inspects Observer permissions equivalently to the other read-only agents and
the runtime must be re-run with the updated verifier to refresh that
evidence. The re-run is a required residual gate and has not been performed
in this update. Phase 5 must enable Observer only after its media path is
directly verified.

Tasks:

- register oh-my-opencode-slim globally;
- create a private preset with selected models and fallbacks;
- set `backgroundJobs.continueOnIdle` to `false`;
- disable slim's worktree skill;
- disable multiplexer, companion, and Council defaults;
- enforce permissions for Explorer, Librarian, Oracle, and Observer;
- replace or narrowly tune Orchestrator, Explorer, and Librarian prompts;
- set concurrency limits;
- add Vietnamese, non-coder, action-first communication rules;
- add OpenChamber advisory policy.

Complete when:

- agents appear correctly in OpenChamber;
- each agent uses the expected model;
- read-only agents cannot mutate through direct tools or shell workarounds;
- a bounded task does not spawn unnecessary subagents.

### Phase 5 - Multimedia Layer

Objective: make screenshots and design evidence safe and predictable.

Status: completed on 2026-08-02. Managed
metadata confirms Terra/Sol are text-only and M3 supports image/video but not
PDF. After source was synchronized to the package commit, an approved temporary
hotfix guarded the package's non-array `disabled_tools` failure and restored
slim initialization. The JPEG hook saves images and a trace confirms the full
path-only task handoff was insufficient because M3 exited without `read`. The
implemented child-session `FilePart` handoff instead passes the OCR smoke; the
temporary path-only Observer activation was rolled back before this structured
handoff replaced it. See `PHASE-5-MULTIMEDIA.md`.

Tasks:

- verify actual GPT media support through CPA GUI;
- test a non-secret metadata overlay if supported;
- enable Observer with enforced read-only permissions while needed;
- test image auto-routing and cleanup;
- document PDF fallback;
- benchmark auto Observer versus direct media.

Complete when:

- image routing works without loading unsupported media into a text-only model;
- no media path is falsely advertised;
- the chosen route has a documented reason and rollback.

### Phase 6 - OpenSpec Project Template

Objective: provide a lightweight project bootstrap.

Tasks:

- create `PRODUCT.md`, optional `DESIGN.md`, and OpenSpec templates;
- add concise proposal, spec, design, task, verification, and release guidance;
- add source-provenance and Context7 evidence sections;
- add risk-based TDD and material-deviation rules;
- keep exactly the five OpenSpec core command names, adapt their prompts for
  session-first interviews, agent-maintained artifacts, next-command advice,
  OpenChamber mode advice, blocked-artifact recovery, and release gates;
- avoid custom OpenSpec schema until pilots show a need.

Complete when:

- a fixture change passes strict OpenSpec validation;
- a small change can use a minimal artifact path;
- a larger change retains traceability without duplicate systems.

### Phase 7 - Execution and Verification

Objective: automate bounded implementation with truthful completion evidence.

Status: runtime-verified on 2026-08-05. The offline evaluator and fixtures
prove the policy contracts; the reviewed global preset prompts and skills were
controlled-applied with per-file backup `phase-7-20260805-180814`, then
`Test-ExecutionVerificationRuntime.ps1` passed against the managed runtime.
This establishes the installed contract, not arbitrary future model compliance.
See `PHASE-7-EXECUTION-AND-VERIFICATION.md`.

Tasks:

- implement task-brief generation;
- implement M3 worker routing;
- implement risk-triggered Oracle review;
- implement two-attempt repair and root-cause escalation;
- create simplified systematic-debugging and verification skills;
- create fixture feature and fixture bug workflows;
- block false completion when commands fail.

Complete when:

- a clear feature completes without unnecessary user questions;
- a bug produces a regression check where appropriate;
- repeated failure triggers assumption review rather than more blind edits;
- failing validation cannot produce a PASS record.

### Phase 8 - OpenChamber Operating Guide

Objective: make the framework guide the user at the right moment.

Status: runtime-verified. The Orchestrator contains explicit
conditional advice for Focus Mode, Session Goals, worktrees, and MultiRun.
`docs/openchamber-operating-guide.md`, advisory fixtures, and an offline
evaluator document and test the user-operating contract. The runtime
verifier hash-compares the active global Orchestrator prompt with the
reviewed Phase 8 source before checking the required rule substrings. Active
target/hash readiness was refreshed on clean commit `e5bb0ed...` and the
target matched, so no reapply was required. Provider/manual behavior evidence
remains a separate rollout concern. See
`PHASE-8-OPENCHAMBER-OPERATING-GUIDE.md`.

Tasks:

- add Focus/Goal/worktree/MultiRun recommendation logic to Orchestrator;
- create concise suggested objective templates;
- document Goal status behavior, budgets, pause/resume, and safe limits;
- verify no conflict between Session Goals and slim background jobs;
- create folder and project-memory conventions.

Complete when:

- the agent recommends the correct mode across advisory eval scenarios;
- it never silently arms Goals or enables permissions;
- one continuation controller is active.

### Phase 9 - UI Quality Layer

Objective: support user-guided design without generic AI UI.

Status: runtime-verified. The framework defines
`PRODUCT.md`/`DESIGN.md`/surface-brief authority, contextual Impeccable and
Taste usage, required desktop/mobile/browser/accessibility evidence, fresh
screenshot review, and explicit human visual approval. The offline evaluator
rejects synthetic-score proof. Active target/hash readiness was refreshed on
clean commit `e5bb0ed...`; the Phase 9 targets matched and no reapply was
required. This does not prove the rendered UI of an arbitrary project. See
`PHASE-9-UI-QUALITY-LAYER.md`.

Tasks:

- add product/design/surface authority ordering;
- integrate selected Impeccable detector and review patterns;
- create desktop/mobile/browser/accessibility checks;
- create screenshot-based independent review;
- keep Taste heuristics optional and contextual.

Complete when:

- a UI fixture preserves the selected direction;
- machine checks and human visual approval are distinguished;
- the framework does not treat a synthetic score as proof.

### Phase 10 - Packaging and Release

Objective: prove that deliverables, not only source code, work.

Status: runtime-verified. The framework provides a project-local package
contract, deterministic clean-install fixture, checksum and delivered-content
checks, verification/release templates, explicit approval gating for external
actions, and strict post-release OpenSpec archive rules. The offline
evaluator and source contract pass; the historic 2026-08-04 record of the
controlled global activation and managed-runtime verification is retained for
provenance. Active target/hash readiness was refreshed on clean commit
`e5bb0ed...`; the Phase 10 targets matched and no reapply was required. The
framework does not release any project; every external release remains a
separately approved operation. See
`PHASE-10-PACKAGING-AND-RELEASE.md`.

Tasks:

- [x] add package-command discovery or project configuration;
- [x] add clean-environment install/run smoke tests;
- [x] add checksum and secret/file-content checks;
- [x] add verification and release templates;
- [x] enforce user approval before external release actions;
- [x] archive release-applicable changes after successful release, and genuine
  no-external-release changes after focused verification, strict validation,
  and `releaseApplicable: false` evidence.

Complete when:

- [x] a fixture artifact installs or runs cleanly;
- [x] release cannot proceed without explicit approval;
- [x] rollback instructions are present.

### Phase 11 - Evaluation and Failure Drills

Objective: validate behavior under realistic failure conditions.

Status: source-complete. The deterministic offline evaluator derives
outcomes for all 21 required scenarios, validates the cross-phase source
contracts, and runs in the Windows pull-request gate. It is a source-policy
regression guard, not live model-compliance evidence or project-native
runtime evidence. The Context7/CodeGraph failure drills inspect the effective
disabled configuration and the disabled-state prompt contract; live model
behavior under the disabled state is a manual gate, not a runtime-verified
claim. See `PHASE-11-EVALUATION-AND-FAILURE-DRILLS.md`.

Required scenarios:

1. Clear request requiring no question.
2. Complex product request requiring adaptive coherent-topic rounds until
   decision-ready, without a fixed question cap or Goal.
3. UI task requiring direction selection.
4. Routine task that must not invoke Deepwork.
5. Dependency requiring Context7.
6. Context7 outage.
7. CodeGraph stale or degraded.
8. M3 worker exceeds file scope.
9. Two failed repairs.
10. Agent proposes a material plan deviation.
11. Test fails while agent tries to claim completion.
12. Package builds but fails clean smoke test.
13. Release requires approval.
14. Release Goal stops at `ready for release` without external action or archive.
15. Goal is evaluating and the user sends no unnecessary continuation.
16. Goal discovers a new material decision and pauses without widening scope.
17. Goal reaches its budget and waits for user choice without auto-resume.
18. Overlapping writer scopes.
19. Long session with obsolete assumptions.
20. Trivial task under Sol/Terra that must stop without fan-out.
21. High-risk task where a scoped Oracle review is justified.

Complete when:

- no critical false-success, unsafe-autonomy, silent-memory-fallback, or
  unbounded-fan-out behavior remains;
- remaining limitations are documented.

### Phase 12 - Global Rollout

Objective: install the verified framework into the personal global environment.

Status: **complete** on 2026-08-08 for immutable candidate
`b75043d6097d12ac52c5bbbc3224f316c3243961`. The final record in
`PHASE-12-GLOBAL-ROLLOUT.md` contains the sanitized command outcomes,
approvals, hashes, no-drift decisions, fresh/existing-project smoke results,
and rollback/reapply evidence. The checklist below remains the required
procedure for any future candidate rollout; prior evidence must not be reused
for a changed candidate.

On 2026-08-13, clean commit `e5bb0ed775a6c1340089a0f299c6699ac533bf20`
passed CI run `31651664360`; its read-only global readiness preflight reported
`NO_APPLY_REQUIRED`, 14/14 targets `MATCH`, Phase 5 `MATCH`, zero drift, and
zero absent targets. This is a no-write target/readiness refresh, not a new full
provider/manual rollout certification.

#### Execution Checklist

Run this checklist in order for one immutable candidate revision. Do not use a
successful check from an earlier revision as evidence for the candidate. Mark an
item only with its command output, exit code, date, and relevant artifact path.

1. [x] **Freeze the candidate.** Confirm the source worktree is clean, record
   its commit SHA, and inspect the diff from the last CI-validated revision.
   Do not start rollout from uncommitted framework source.
2. [x] **Run the current-revision source and fixture gates.** Run the local
   source gates in this order: `Test-FrameworkSkeleton.ps1`,
   `Test-ResearchConfigSchema.ps1`, `Test-AgentLayer.ps1`,
   `Test-ExecutionVerification.ps1`,
   `Test-OpenChamberOperatingGuide.ps1`, `Test-UIQualityLayer.ps1`,
   `Test-ObserverAttachmentRegression.ps1`,
   `Test-GlobalApplyReadinessRegression.ps1`,
   `Test-ExecutionVerificationApply.ps1`,
   `Test-CiWindowsOnlyRegression.ps1`, and
   `Test-EvaluationFailureDrills.ps1`. Then run the isolated temporary gates:
   `Test-ObserverAttachmentPreflight.ps1`,
   `Test-PackagingRelease.ps1`, and
   `Test-OpenSpecProjectTemplate.ps1`, plus `Test-OpenSpecLifecycle.ps1` when
   validating local/store lifecycle and archive branches. These gates must not modify global
   OpenCode or OpenChamber configuration; the package and Observer negative
   gates create and remove only their own temporary fixtures, while the OpenSpec
   fixture may retrieve the pinned CLI through `npx`.
3. [x] **Obtain current-revision Windows CI evidence.** Push or open a pull
   request for the candidate and require the `Research Configuration` workflow
   to pass on that same SHA. Its copied-bootstrap preflight additionally proves
   the exact global `@fission-ai/openspec@1.5.0` CLI and a fresh template copy.
   A green run for an earlier SHA is not sufficient.
4. [x] **Create the pre-apply evidence manifest and diff preview.** Record the
   active OpenChamber and managed OpenCode versions, active plugin and patch
   identity, MCP/auth state without credentials, framework-owned target paths,
   and current SHA-256 values. Compare each reviewed source with its named
   target and classify it as `MATCH`, `DRIFT`, or `ABSENT`. A `MATCH` target is
   not reapplied. An `ABSENT` required target is `BLOCKED` under the current
   preflight contract. For every supported `DRIFT` target, record the owner,
   approved apply script, planned backup location, expected after hash, focused
   verifier, rollback action, restart requirement, and side effect. Never add
   CPA GUI-managed `opencode.json`, OpenChamber state, credentials, sessions,
   or runtime files to this manifest.
5. [x] **Approval checkpoint.** Present the candidate SHA, source/CI evidence,
   latest runtime evidence and the stale runtime gates still required, diff
   preview, exact target list, backup paths, planned writes, restart, live-model
   smoke cost, and rollback procedure. Obtain explicit user approval before
   creating backups, changing a persistent global target, restarting
   OpenChamber, or making a live provider request.
6. [x] **Refresh stale runtime evidence after approval and before a write.**
   The managed OpenCode version has changed since the recorded Phase 3 evidence,
   so run `Test-ResearchRuntime.ps1` and perform its documented manual
   disabled-MCP live behavioral check. Re-run any Phase 4, 5, or 7-10 runtime
   verifier only if its source, managed version, plugin version, prompt/skill
   target, or package patch changed after its recorded evidence. If the slim
   package was reinstalled or updated, Phase 5 additionally requires
   `Test-MultimediaCapabilities.ps1`,
   `Test-ObserverAttachment.ps1 -PreflightOnly`, and the live
   `Test-ObserverAttachment.ps1` OCR smoke. Stop before creating a backup or
   applying a target if any required runtime or behavior gate fails.
7. [x] **Apply only approved drift.** Close OpenChamber and CPA GUI. Create
   timestamped file-level backups outside this repository, record before hashes,
   and use only the reviewed phase-specific apply scripts for approved targets.
   Do not run an apply script merely to reproduce an already matching target,
   do not manually merge JSON, and stop immediately if a script refuses or a
   hash check fails. The only exception is the explicit no-drift rollback
   verification reapply in item 10; it requires its own approval and must use
   only the named Phase 8 script and target below. Record every created manifest
   and after hash.
8. [x] **Restart and verify affected runtime contracts.** Restart
   OpenChamber, run `opencode debug config` through the managed binary, and run
   the focused runtime verifier for every changed layer. At minimum, a change to
   the agent/preset, research MCP, multimedia patch, Phase 7 execution assets,
   Phase 8 guidance, Phase 9 UI assets, or Phase 10 release assets requires its
   corresponding runtime verifier. A failed verifier is a rollback trigger, not
   a condition for a second blind apply.
9. [x] **Run final project smokes.** In a fresh temporary project, copy
   `templates\project`, run its `Test-OpenSpecBootstrapPreflight.ps1`, and
   validate a minimal OpenSpec change with the pinned CLI. In one user-selected
   existing project, run only a bounded, non-destructive smoke with named
   project-native evidence. Record the selected project, command, result, and
   remaining uncertainty; do not treat a fixture command as evidence for that
   project.
10. [x] **Prove rollback.** With explicit approval, restore the exact named
    targets from the Phase 12 backup manifests, restart OpenChamber, and run the
    focused verifiers that demonstrate the restoration. Reapply only the same
    approved drift through the reviewed scripts, restart, and repeat the
    affected runtime checks. Do not restore a directory, use destructive Git
    commands, or modify OpenChamber state. If every approved target is `MATCH`
    and no Phase 12 apply created a backup manifest, pause rather than treating
    rollback as implicitly proven. The user may separately approve one
    verification reapply of only
    `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md`
    through `Apply-OpenChamberOperatingGuide.ps1`. The script creates the
    `phase-8-*` backup manifest used by this drill. Restore that one target with
    `Invoke-Phase12RollbackDrill.ps1`, restart OpenChamber, run
    `Test-OpenChamberOperatingGuideRuntime.ps1`, then reapply through the same
    Phase 8 script, restart, and rerun the verifier. The target must be a
    byte-identical `MATCH` before and after this verification reapply. Record
    that this proves the reviewed file-level backup/restore/reapply mechanism,
    not a behavioral reversal of differing content.
11. [x] **Close the rollout record.** Record the candidate SHA, all command
    outputs and exit codes, CI URL, active versions, before/after checksums,
    backup locations, diff outcome, apply/no-op decisions, smoke results,
    rollback result, and remaining limitations. Confirm the repository contains
    no secret-bearing file before marking Phase 12 complete.

Complete when:

- the global framework works in a fresh project and an existing project;
- rollback is proven;
- no secret-bearing file entered `D:\Projects\SDD`.

## 20. Evaluation Gates

The framework is not complete until these claims have evidence:

| Claim | Evidence |
|---|---|
| Global config is valid | Schema validation and `opencode debug config` |
| Plugin is active | Slim agents appear in OpenChamber/OpenCode |
| Model routing is correct | Runtime logs show expected provider/model per agent |
| Effort mapping is known | Controlled task and transport evidence |
| Context7 is mandatory | Dependency fixture records evidence or blocks correctly |
| CodeGraph fails soft | Stale/degraded fixture uses direct tools appropriately |
| Worktrees are not duplicated | Only OpenChamber creates and cleans worktrees |
| Continuation is not duplicated | Only Session Goals continue parent sessions |
| Read-only agents are enforced | Mutation and shell-workaround probes fail |
| Workers stay in scope | File-ownership fixture |
| Sol/Terra do not over-orchestrate | Trivial and medium task fan-out metrics |
| Review is proportionate | Routine task has no independent review; risky task does |
| Completion is truthful | Failed commands cannot create PASS |
| Package is real | Clean install/run smoke test |
| Release is safe | External action cannot occur without approval |
| User guidance is correct | Focus/Goal/worktree advisory scenarios |

## 21. Rollback Requirements

Every implementation phase that changes the global installation must provide:

- affected file list;
- backup path;
- before checksum;
- after checksum;
- validation command;
- rollback command or exact restoration steps;
- restart requirement;
- known side effects.

Do not use destructive Git or filesystem rollback commands. Restore only files
created or changed by this framework, and preserve unrelated user changes.

## 22. Final Decision Summary

The final design decisions are:

1. The framework targets one private personal OpenCode environment; its source
   repository and reviewed source-release assets may be public.
2. `D:\Projects\SDD` is the source, evaluation, and rollback-contract
   workspace. Secret runtime state and protected backups stay outside it.
3. OpenChamber is the control plane.
4. oh-my-opencode-slim provides specialist orchestration after lean prompt
   changes.
5. OpenSpec is the only per-project specification/change backbone.
6. Context7 is mandatory for external API and dependency evidence.
7. CodeGraph supports local structural research; project commands prove runtime
   correctness.
8. M3 `none` is the initial baseline for Librarian, Explorer, and Fixer.
9. M3 `thinking` is reserved for Designer and difficult bounded escalation.
10. Terra and Sol start at effective Medium/default, not XHigh.
11. Librarian and Explorer compare only M3 `none` and M3 `thinking`; no Codex
    Spark route is part of the framework model selection.
12. Sol XHigh and Max are not global defaults.
13. Superpowers is mined for selected mechanisms but not installed globally.
14. One focused search batch, two concurrent subagents, one normal review, and
    one scoped re-review are the default upper bounds.
15. Observer is enabled only through the reviewed M3 structured-image route,
    remains read-only, and must be revalidated after the pinned slim package is
    reinstalled or upgraded.
16. The agent advises when to use Focus Mode, Session Goals, worktrees, or
    neither, but the user controls activation and external actions.
17. The user approves product intent, material UI direction, material plan
    deviations, destructive/costly actions, and release.
18. The framework stops when acceptance criteria pass and records optional
    improvements as follow-ups.

## 23. Next Action

Phase 12 is complete for candidate
`b75043d6097d12ac52c5bbbc3224f316c3243961`. For any future framework candidate
or managed-runtime change, first run the deterministic read-only readiness
preflight. If it returns `NO_APPLY_REQUIRED`, do not run apply or rollback. If a
new full rollout certification is required, begin at checklist item 1 and do
not reuse provider/manual, smoke, approval, or rollback evidence from another
SHA. Do not perform a global write, restart, provider call, or rollback drill
before the candidate reaches the explicit approval checkpoint at item 5.
