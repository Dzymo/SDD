# Decisions

| Date | Decision | Status | Evidence | Consequence |
|---|---|---|---|---|
| 2026-08-02 | Keep this framework private and source-only. | Accepted | `PLAN.md` sections 1, 3, and 5 | No package manifest, marketplace metadata, or public distribution files. |
| 2026-08-02 | Create the Phase 2 skeleton without global configuration sources. | Accepted | `PLAN.md` Phase 2; `PHASE-0-BASELINE.md` ownership table | `config/` remains empty except for directory markers. |
| 2026-08-02 | Never import OpenChamber state or provider configuration into the workspace. | Accepted | `PHASE-0-BASELINE.md` secret and state exclusions | Backups remain in the protected local data path; workspace checks reject common credential markers. |
| 2026-08-02 | Treat `PLAN.md` as the framework implementation source of truth. | Accepted | `PLAN.md` document status | Amend the plan before a later phase changes architecture, routing, safety boundaries, or workflow. |
| 2026-08-02 | Retain the Phase 1 model-route selections as provisional role evidence. | Accepted | `PHASE-1-MODEL-BENCHMARK.md` | Phase 3-5 must test retrieval, permissions, and media before treating route availability as production capability. |
| 2026-08-02 | Define a closed, non-secret research-MCP source schema before any Phase 3 installation. | Accepted | `D:\Projects\Docs\codegraph\src\installer\targets\opencode.ts`; `D:\Projects\Docs\context7\plugins\cursor\context7\mcp.json`; `config\opencode\research-mcp.schema.json` | The schema permits only the reviewed Context7 OAuth endpoint and CodeGraph command. `additionalProperties: false` excludes headers, environment variables, credentials, and extra MCP servers. `scripts\Test-ResearchConfigSchema.ps1` validates a positive fixture and rejects authentication, endpoint, and command deviations. |

## Change Record Rule

Before adding an important framework component, record its need, inspected
repositories and exact paths, candidate mechanism, reuse/adapt/new decision,
reason, rejected alternative, and verification. This is the source-first policy
from `PLAN.md`; it prevents the framework from accumulating copied components
without a concrete reason.
