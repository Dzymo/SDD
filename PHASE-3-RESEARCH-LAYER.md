# Phase 3 Research Layer

Date: 2026-08-03

## Result

Phase 3 is **PASS**. The managed OpenChamber OpenCode `1.18.11` runtime loads
the reviewed OAuth-only Context7 MCP and local CodeGraph MCP. Context7 OAuth is
authenticated without storing credentials in this repository. CodeGraph `1.5.0`
indexes the reviewed local reference at `D:\Projects\Docs\codegraph`.
The durable managed-runtime gate passed again on 2026-08-05.

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
| Context7 failure is fail-soft | Temporary process config disables Context7; effective config inspection plus prompt-based behavioral assertion | PASS: config inspection confirms `mcp.context7.enabled` is `false`; the prompt-based assertion confirms the Librarian prompt instructs the model to report unavailable verified evidence. |
| CodeGraph failure is fail-soft | Temporary process config disables CodeGraph; effective config inspection plus prompt-based behavioral assertion | PASS: config inspection confirms `mcp.codegraph.enabled` is `false`; the prompt-based assertion confirms the Explorer prompt instructs the model to report unavailable local evidence and to never infer missing paths or lines. |

`scripts\Test-ResearchRuntime.ps1` is the durable gate. It validates the
effective managed configuration, MCP availability, authenticated Context7,
indexed CodeGraph reference, versioned Context7 evidence, local CodeGraph path
evidence, and temporary disabled-MCP fixtures. The fixture assertions inspect
the effective disabled configuration and the enforced fallback prompts so that
the repeatable gate does not depend on a model's exact phrasing.

### Config Inspection Versus Behavioral Assertion

The disabled-MCP section separates two kinds of evidence:

| Kind | What it inspects | Coverage |
|---|---|---|
| Config inspection | The effective `opencode debug config` output after a temporary overlay disables Context7 or CodeGraph. | Confirms the plugin honors the disabled flag and the effective prompt is the disabled-state prompt. |
| Prompt-based behavioral assertion | The disabled-state prompt text contains the required fail-soft instructions (`verified external evidence is unavailable`, `local evidence is unavailable`, `never infer missing paths or lines`). | Confirms the contract the model is told to follow, not what the model actually does. |

A live behavioral assertion (`opencode run` with the disabled overlay and a
real model call) would require a provider and is **not** executed by this
script. It is documented as a **manual gate**: rerun
`Test-ResearchRuntime.ps1` after a model, prompt, or plugin change, then
exercise the disabled scenario in a disposable project with the actual
managed runtime and the live M3 or Terra model to manually confirm the model
reports the unavailability instead of inferring from memory.

## Limits

- Context7 OAuth state remains outside this repository and is never printed or
  copied into an artifact.
- The indexed CodeGraph reference is `D:\Projects\Docs\codegraph`. Other
  projects must run `codegraph init` before structural MCP queries can use them.
- The current OpenChamber child runtime can omit built-in local inspection tools
  when CodeGraph is disabled. That fallback therefore reports unavailable direct
  evidence instead of inventing a substitute path or line range.
- The disabled-MCP fixture verifies the effective config and the prompt
  contract. It does not call a model, so live model behavior under the
  disabled state is a manual gate, not a runtime-verified claim.

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
