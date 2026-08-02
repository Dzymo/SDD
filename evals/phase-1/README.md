# Phase 1 Model and Prompt Benchmarks

This evaluation measures the routes available to the managed OpenChamber
runtime on 2026-08-02. It does not modify global configuration.

## Provenance

| Need | Repositories inspected | Candidate mechanism | Decision | Reason |
|---|---|---|---|---|
| Reproducible response evaluation | `D:\Projects\Docs\i-have-adhd\evals\README.md`, `rubric.md`, `cases.jsonl` | Fixed cases, pinned models, raw records, explicit rubric | adapt | The mechanism is compact and directly supports route comparison. |
| Isolation and limits | `D:\Projects\Docs\ponytail\benchmarks\agentic\README.md` | Fresh context per cell, preserved raw evidence, limits stated with findings | adapt | It prevents session history from contaminating comparison without importing its large harness. |

Rejected alternatives: the full `i-have-adhd` runner targets Claude/Codex CLIs;
the Ponytail harness requires seeded repositories and a different agent runtime.
Neither is the smallest way to benchmark the managed OpenChamber routes.

## Conditions

| Condition | Model | Variant | Intended role |
|---|---|---|---|
| `m3-none` | `minimax-coding-plan/MiniMax-M3` | `none` | Librarian, Explorer, Fixer baseline |
| `m3-thinking` | `minimax-coding-plan/MiniMax-M3` | `thinking` | Difficult bounded escalation and Designer baseline |
| `terra-default` | `cliproxy/gpt-5.6-terra` | default (`medium`) | Orchestrator baseline |
| `terra-high` | `cliproxy/gpt-5.6-terra` | `high` | Orchestrator challenger |
| `sol-default` | `cliproxy/gpt-5.6-sol` | default (`medium`) | Oracle baseline |
| `sol-high` | `cliproxy/gpt-5.6-sol` | `high` | Oracle challenger |

Every condition receives the same prompt and runs in a fresh OpenChamber
session. The evaluator does not supply global skills, prior conversation, or
repository tasks. The evaluator records the session identifier, selected model,
completion status, elapsed time, exact response, and manual scores.

The first execution used stale `cpa-gui/*` conditions after that provider had
already been removed from the effective configuration. Those four records are
preserved in `invalid-cpa-route-results.json`; they do not score the models.
The current `results.json` contains the valid rerun against the routes above.

## Fixed Prompt

```text
You are being evaluated. Do not use tools, browse, delegate, edit files, or ask
questions. Return exactly one JSON object and no Markdown.

Task: A user says: "Fix the typo 'recieve' to 'receive' in README.md. The file
and replacement are known. Do not change any other file. Verify the result by
searching README.md after the edit."

Score this task decision under these rules:
- Direct execution is required for a bounded change with known file and clear
  acceptance criteria.
- Delegation, a worktree, a plan, an independent review, or a user question is
  unnecessary.
- The focused verification is `rg -n "recieve|receive" README.md`.

Return JSON with exactly these keys and values:
{"decision":"direct-execution","delegate":false,"ask_user":false,"worktree":false,"verification":"rg -n \\"recieve|receive\\" README.md","reason":"..."}
```

The case assesses the plan's anti-overthinking policy: correct routing,
unnecessary escalation, output-contract compliance, and concise stopping logic.
It does not claim to measure implementation correctness, Context7 retrieval,
media handling, cost, or production reliability.

## Scoring

| Metric | Pass condition |
|---|---|
| Runtime completion | The session finishes without a route or provider error. |
| Contract compliance | Exactly one parseable JSON object with no extra keys. |
| Task correctness | Required decision values and verification string match. |
| Scope discipline | The reason does not add research, subagents, a plan, review, worktree, or user question. |
| Latency | Wall-clock seconds from session dispatch to idle result; descriptive only. |

The comparator is the paired default/high or `none`/`thinking` route. One run
per condition is a routing smoke benchmark, not a statistical performance
claim. A challenger replaces a baseline only if it meets all gates and has a
material, observed benefit for the role; otherwise retain the lower-complexity
baseline.

## Verification

Run `PowerShell -File scripts\verify-phase-1.ps1` from `D:\Projects\SDD`
after results are written. The verifier parses the raw JSON response saved for
each completed condition, checks the deterministic contract fields, and checks
for every valid condition.
