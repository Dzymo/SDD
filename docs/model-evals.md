# Model Evaluations

## Current Evidence

Phase 1 selected baseline and fallback routes through a bounded routing smoke
benchmark. The authoritative result is
`PHASE-1-MODEL-BENCHMARK.md`, with raw records and verifier under
`evals/phase-1/`.

| Role | Baseline | Fallback | Limitation |
|---|---|---|---|
| Librarian | MiniMax M3 `none` | MiniMax M3 `thinking` | Context7 retrieval and citation accuracy have not yet been tested. |
| Explorer | MiniMax M3 `none` | MiniMax M3 `thinking` | Local-search and CodeGraph recall have not yet been tested. |
| Fixer | MiniMax M3 `none` | MiniMax M3 `thinking` | Implementation quality has not yet been benchmarked. |
| Designer | MiniMax M3 `thinking` | MiniMax M3 `none` | Visual implementation review is deferred. |
| Observer | MiniMax M3 `none` | MiniMax M3 `thinking` | Media routing and read-only enforcement are deferred. |
| Orchestrator | CLIProxy Terra default (`medium`) | Terra `high` | Only bounded routing behavior is evidenced. |
| Oracle | CLIProxy Sol default (`medium`) | Sol `high` | Independent-review quality is untested. |

## Re-run

```powershell
PowerShell -ExecutionPolicy Bypass -File .\evals\phase-1\scripts\verify-phase-1.ps1
```

Do not convert routing availability into an unsupported claim about tool use,
retrieval, permissions, cost, media support, or production reliability.
