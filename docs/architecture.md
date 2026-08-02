# Architecture

## Scope

This repository is the private source layer for a personal OpenCode workflow.
OpenChamber remains the control plane; oh-my-opencode-slim will provide agent
routing when Phase 4 activates it; OpenSpec remains project-local.

```text
OpenChamber
  session, worktree, goal, release control
       |
       v
OpenCode and oh-my-opencode-slim
  future global configuration, prompts, skills, commands
       |
       +-- Context7 and CodeGraph evidence (Phase 3)
       +-- project-local OpenSpec artifacts
       |
       v
Project-native validation and explicit user release approval
```

## Source Boundaries

| Layer | Location | Owner | Rule |
|---|---|---|---|
| Framework source | `D:\Projects\SDD` | This framework | Contains only reviewed, non-secret source and evidence. |
| Global OpenCode configuration | `C:\Users\quang\.config\opencode` | Established per file | Do not write until a later phase identifies a supported owner path. |
| OpenChamber settings and runtime | `C:\Users\quang\.config\openchamber` | OpenChamber | Never copy, edit, back up, or restore through this framework. |
| Product and change artifacts | Participating project | Project | Remain project-local. |
| Protected backups | `C:\Users\quang\.local\share\opencode\framework-backups` | User | Stay outside this workspace. |

## Source Layout Contract

`config/opencode/` and `config/oh-my-opencode-slim/` are reserved for reviewed,
non-secret sources. Phase 3 adds only `config/opencode/research-mcp.schema.json`:
it describes the approved Context7 OAuth and local CodeGraph entries, but is not
a deployable global configuration file. Its closed shape excludes headers,
environment variables, authentication, and unapproved MCP servers.

Prompts, skills, commands, templates, fixtures, and future configuration are
added only by their owning phase. The source layout must not become a second
workflow controller, worktree manager, or release authority.

## Provenance

| Need | Repositories inspected | Candidate mechanism | Decision | Reason |
|---|---|---|---|---|
| Keep generated configuration separate from its source | `D:\Projects\Docs\oh-my-opencode-slim\README.md` | Preset configuration generated from a dedicated config file | adapt | Reserve dedicated source directories and require explicit staging rather than mixing sources with runtime state. |
| Keep evaluation evidence reproducible | `D:\Projects\Docs\i-have-adhd\evals\README.md` | Fixed inputs, isolated conditions, recorded result artifacts | adapt | Preserve checks and raw evaluation evidence under `evals/` without importing an unrelated runner. |

Rejected: copying a full plugin preset now would introduce unvalidated provider
and agent settings before the Phase 3 and Phase 4 evidence gates.
