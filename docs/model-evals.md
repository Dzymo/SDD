# Model Evaluations

## Current Evidence

Phase 1 selected baseline and fallback routes through a bounded routing smoke
benchmark. The authoritative result is
`PHASE-1-MODEL-BENCHMARK.md`, with raw records and verifier under
`evals/phase-1/`.

| Role | Baseline | Fallback | Limitation |
|---|---|---|---|
| Librarian | MiniMax M3 `none` | MiniMax M3 `thinking` | Phase 3 runtime evidence covers Context7 versioned library retrieval (Zod `v4.0.1`) for the resolved `/colinhacks/zod` library; broader citation and accuracy coverage across more libraries is not yet benchmarked. |
| Explorer | MiniMax M3 `none` | MiniMax M3 `thinking` | Phase 3 runtime evidence covers a single CodeGraph `MCPServer` lookup; broader cross-repository recall and structural queries are not yet benchmarked. |
| Fixer | MiniMax M3 `none` | MiniMax M3 `thinking` | Implementation quality has not yet been benchmarked on real project tasks. |
| Designer | MiniMax M3 `thinking` | MiniMax M3 `none` | Visual implementation review is deferred; project-native browser and accessibility checks remain project-local. |
| Observer | MiniMax M3 `none` | MiniMax M3 `thinking` | Phase 5 evidence covers a fresh per-run structured `FilePart` OCR smoke; direct provider-payload capture and live denied-tool probes remain separate residual gates. |
| Orchestrator | CLIProxy Terra default (`medium`) | Terra `high` | Only bounded routing behavior is evidenced; live task compliance, repair escalation, and Goal advisory quality are not yet benchmarked. |
| Oracle | CLIProxy Sol default (`medium`) | Sol `high` | Independent-review quality is untested on real risk-triggered reviews. |

## Re-run

```powershell
PowerShell -ExecutionPolicy Bypass -File .\evals\phase-1\scripts\verify-phase-1.ps1
```

Do not convert routing availability into an unsupported claim about tool use,
retrieval, permissions, cost, media support, or production reliability. The
limitations column reflects what is actually evidenced; do not treat absence
as implicit capability.
