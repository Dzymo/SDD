# Phase 3 Research Layer

Date: 2026-08-03

## Result

Phase 3 is **PASS**. The managed OpenChamber OpenCode `1.18.11` runtime loads
the reviewed OAuth-only Context7 MCP and local CodeGraph MCP. Context7 OAuth is
authenticated without storing credentials in this repository. CodeGraph `1.5.0`
indexes the reviewed local reference at `D:\Projects\Docs\codegraph`.

## Applied Sources

| Source | Global target | Rule |
|---|---|---|
| `config\opencode\research-mcp.json` | `C:\Users\quang\.config\opencode\opencode.jsonc` | Merge only the Context7 OAuth and CodeGraph MCP objects. |
| `config\opencode\research-references.json` | `C:\Users\quang\.config\opencode\opencode.jsonc` | Merge only the hidden `codegraph` local reference. |
| `config\oh-my-opencode-slim\sdd-personal.json` | `C:\Users\quang\.config\opencode\oh-my-opencode-slim.json` | Give Librarian only `context7` and Explorer only `codegraph`. |
| Preset Explorer and Librarian prompts | `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\` | Require source-first behavior and explicit fail-safe reporting. |
| `skills\source-first-research\SKILL.md` | `C:\Users\quang\.config\opencode\skills\source-first-research\SKILL.md` | Reusable source/fallback policy. |

## Source Validation

| Claim | Evidence | Result |
|---|---|---|
| Approved Context7 OAuth endpoint and local CodeGraph command are accepted | `fixtures\phase-3\research-mcp.valid.json` validated by `scripts\Test-ResearchConfigSchema.ps1` | PASS |
| Authentication fields are rejected | `fixtures\phase-3\research-mcp.invalid-auth.json` | PASS |
| Alternate CodeGraph command is rejected | `fixtures\phase-3\research-mcp.invalid-command.json` | PASS |
| Non-OAuth Context7 endpoint is rejected | `fixtures\phase-3\research-mcp.invalid-url.json` | PASS |

The source validator accepts the deployable MCP fragment as well as the
approved fixture, and rejects authentication, endpoint, and command deviations.

## Runtime Evidence

| Claim | Evidence | Result |
|---|---|---|
| Managed runtime loads only the approved Context7 OAuth endpoint and CodeGraph command | `scripts\Test-ResearchRuntime.ps1`; `opencode mcp list` | PASS: both MCPs connected. |
| Context7 is authenticated and returns versioned library evidence | Librarian delegated through Orchestrator | PASS: `/colinhacks/zod`, `v4.0.1`, and the official Zod `z.object` documentation reference. |
| CodeGraph returns exact local structural evidence | Explorer delegated through Orchestrator, then source boundary verification | PASS: `MCPServer` spans `D:\Projects\Docs\codegraph\src\mcp\index.ts:189-474`. |
| CodeGraph reference is healthy | `codegraph status` | PASS: 456 files, 9,218 nodes, and 36,587 edges are indexed and current. |
| Context7 failure is fail-soft | Temporary process config disables Context7; direct Librarian fallback run and durable effective-prompt fixture | PASS: it reports that verified external evidence is unavailable rather than using model memory when web retrieval is not exposed. |
| CodeGraph failure is fail-soft | Temporary process config disables CodeGraph; direct Explorer fallback run and durable effective-prompt fixture | PASS: it reports no direct local evidence rather than inferring a path or line range when inspection tools are not exposed. |

`scripts\Test-ResearchRuntime.ps1` is the durable gate. It validates the
effective managed configuration, MCP availability, authenticated Context7,
indexed CodeGraph reference, versioned Context7 evidence, local CodeGraph path
evidence, and temporary disabled-MCP fixtures. The fixture assertions inspect
the effective disabled configuration and the enforced fallback prompts so that
the repeatable gate does not depend on a model's exact phrasing.

## Limits

- Context7 OAuth state remains outside this repository and is never printed or
  copied into an artifact.
- The indexed CodeGraph reference is `D:\Projects\Docs\codegraph`. Other
  projects must run `codegraph init` before structural MCP queries can use them.
- The current OpenChamber child runtime can omit built-in local inspection tools
  when CodeGraph is disabled. That fallback therefore reports unavailable direct
  evidence instead of inventing a substitute path or line range.

## Backup And Rollback

The initial Phase 3 file-level backup and manifest are at:

`C:\Users\quang\.local\share\opencode\framework-backups\phase-3-20260803-171732`

It records before/after SHA-256 for the five applied targets, including the
previously absent skill file. The later prompt-policy refinement has its own
backup at `phase-3-20260803-173550`; use the initial backup to remove the whole
Phase 3 activation. Restore only its listed files, remove the skill file if it
was absent before activation, restart OpenChamber, and run `opencode mcp list`
plus `Test-AgentLayerRuntime.ps1`. Do not restore directories or OpenChamber
state.

## Re-run

Run from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ResearchConfigSchema.ps1
```

For the managed runtime gate:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ResearchRuntime.ps1
```
