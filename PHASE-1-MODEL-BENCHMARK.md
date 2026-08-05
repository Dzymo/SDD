# Phase 1 Model and Prompt Benchmarks

Date: 2026-08-02

## Status

**Completed as a bounded route-selection smoke benchmark.** M3 `none` and
`thinking`, CLIProxy Terra default/`high`, and CLIProxy Sol default/`high` all
passed the deterministic routing contract in fresh sessions. The invalid
historical `cpa-gui/*` records are preserved separately and do not affect model
selection.

The benchmark harness made no global configuration write. It ran after a
provider change outside this framework switched the active route to CLIProxy;
the missing backup/rollback record for that historical change is retained as a
provenance limitation, not treated as framework-controlled evidence.

## Method

The compact harness is documented in `evals/phase-1/README.md`; raw results
are in `evals/phase-1/results.json`.

It adapts two inspected source mechanisms:

| Need | Source | Mechanism adapted | Reason |
|---|---|---|---|
| Fixed comparable conditions | `D:\Projects\Docs\i-have-adhd\evals\README.md` and `rubric.md` | Fixed prompt, pinned route, raw result, explicit pass criteria | Directly suited to route selection. |
| Contamination prevention | `D:\Projects\Docs\ponytail\benchmarks\agentic\README.md` | Fresh context for every condition and explicit limitation reporting | Prevents session history or global context from changing only one condition. |

Each condition used a fresh OpenChamber session with the same tool-free,
JSON-only prompt. The task checks direct-execution routing for a known,
single-file typo change. It deliberately tests no retrieval, edits, external
APIs, media, or implementation capability.

## Environment

| Component | Value |
|---|---|
| OpenChamber | `1.17.1` at Phase 0 capture |
| Managed OpenCode reported by benchmark sessions | `1.18.11` |
| Bundled OpenCode binary after benchmark | `1.18.11` |
| Shell `opencode` from Phase 0 | `1.18.5` |
| Active provider after the switch | `cliproxy` only, using `@ai-sdk/openai` |

The bundled OpenCode runtime drifted from `1.18.9` at Phase 0 to `1.18.11`
during Phase 1. The provider configuration changed at
`2026-08-02T04:18:00.4219681Z`: the current config retains `cliproxy` and
removes `cpa-gui`. The first M3 benchmark began at `05:18:56Z`; the stale
Terra and Sol conditions began at `05:19Z` and `05:24Z`, respectively.
Results are tied to these versions and configuration boundaries.

## Results

| Condition | Route | Result | Evidence | Latency |
|---|---|---|---|---:|
| `m3-none` | `minimax-coding-plan/MiniMax-M3`, `none` | PASS | Exact JSON contract; direct execution; no delegation/question/worktree; exact focused verification command | 2.365 s |
| `m3-thinking` | `minimax-coding-plan/MiniMax-M3`, `thinking` | PASS | Exact JSON contract; direct execution; no delegation/question/worktree; exact focused verification command | 2.375 s |
| `terra-default` | `cliproxy/gpt-5.6-terra`, default `medium` | PASS | Exact JSON contract; direct execution; no delegation/question/worktree; exact focused verification command | 4.901 s |
| `terra-high` | `cliproxy/gpt-5.6-terra`, `high` | PASS | Exact JSON contract; direct execution; no delegation/question/worktree; exact focused verification command | 2.934 s |
| `sol-default` | `cliproxy/gpt-5.6-sol`, default `medium` | PASS | Exact JSON contract; direct execution; no delegation/question/worktree; exact focused verification command | 4.382 s |
| `sol-high` | `cliproxy/gpt-5.6-sol`, `high` | PASS | Exact JSON contract; direct execution; no delegation/question/worktree; exact focused verification command | 3.592 s |

This one-run fixture establishes route availability and compliance with the
anti-overthinking routing contract. The observed latency differences are
descriptive only and were not used to rank default against `high`.

## Decisions

| Agent role | Decision | Evidence and limitation |
|---|---|---|
| Librarian | Baseline: M3 `none`; fallback: M3 `thinking` | Both pass the bounded routing smoke test. Retrieval accuracy, citations, and Context7 behavior remain untested until Phase 3. |
| Explorer | Baseline: M3 `none`; fallback: M3 `thinking` | Both pass the bounded routing smoke test. Local search recall and CodeGraph behavior remain untested until Phase 3. |
| Fixer | Provisional baseline: M3 `none`; escalation: M3 `thinking` | Supported by route availability and the same routing test only. It is not an implementation-quality benchmark. |
| Designer | Baseline: M3 `thinking`; fallback: M3 `none` | Route selection only; design implementation and visual-review quality are intentionally deferred to Phase 9. |
| Observer | Baseline: M3 `none`; fallback: M3 `thinking` | Conditional role; media routing and read-only permissions remain deferred to Phase 5. |
| Orchestrator | Baseline: CLIProxy Terra default (`medium`); fallback: Terra `high` | Both routes pass. Escalate only for a named difficult task under the effort policy. |
| Oracle | Baseline: CLIProxy Sol default (`medium`); fallback: Sol `high` | Both routes pass. `xhigh` remains outside the default global framework. |
| OpenChamber small model | No selection | It was out of scope for this Phase 1 route matrix. |

## Historical Invalid CPA GUI Conditions

The first four CPA GUI conditions are retained only as provenance in
`evals/phase-1/invalid-cpa-route-results.json`. The switch to direct CLIProxy
is the cause of their apparent Terra/Sol failure:

1. `opencode.json` changed to `cliproxy` only at `04:18:00Z`.
2. `cpa-gui/gpt-5.6-terra` and `cpa-gui/gpt-5.6-sol` were not registered in the
   effective configuration after that switch.
3. The stale CPA conditions began at `05:19Z` and `05:24Z`, after their
   provider was removed.
4. The valid rerun used fresh sessions for `cliproxy/gpt-5.6-terra` and
   `cliproxy/gpt-5.6-sol`, at default `medium` and explicit `high`; all four
   conditions passed.
5. Current `cliproxy` metadata maps each route's default to `medium` effort
   and exposes a `high` variant.

CPA GUI is retired from framework model selection. Do not restore it solely for
this benchmark. Keep the invalid CPA records as provenance; do not score them,
use them to judge model behavior, or infer effort from their old suffixes.

## Verification

```powershell
PowerShell -ExecutionPolicy Bypass -File .\evals\phase-1\scripts\verify-phase-1.ps1
```

The verifier confirms all six valid JSON contracts in `results.json`. The stale
CPA conditions are stored separately and are not scored.
