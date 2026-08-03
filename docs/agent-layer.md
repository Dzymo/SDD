# Agent Layer

## Purpose

Phase 4 activates the private, lean `oh-my-opencode-slim` preset for the
managed OpenChamber OpenCode runtime. The preset is source-controlled here and
applied only to user-owned OpenCode configuration files. It never changes the
CPA GUI-managed `opencode.json`, its state sidecar, or OpenChamber state.

## Reviewed Sources

| Need | Repositories and paths inspected | Candidate mechanism | Decision | Verification |
|---|---|---|---|---|
| Agent registration and preset model routing | `D:\Projects\Docs\oh-my-opencode-slim\docs\configuration.md`; `src\config\schema.ts`; `src\agents\index.ts` | Slim global preset with ordered model entries | adapt | `Test-AgentLayer.ps1` validates the pinned source and expected primary/fallback routes. |
| Read-only research and advisory lanes | `D:\Projects\Docs\oh-my-opencode-slim\src\agents\permissions.ts`; `docs\configuration.md` | Wildcard-deny permissions with an allow-list of inspection tools | adapt | Source and runtime verifiers require edit, shell, delegation, and external-directory denial. |
| Prompt replacement behavior | `D:\Projects\Docs\oh-my-opencode-slim\docs\configuration.md`; `src\config\loader.ts` | Preset-specific `{agent}.md` replacement files | reuse | Runtime loads replacement prompts from the preset directory. |

Rejected: the upstream default Orchestrator prompt, because it mandates
delegation for multi-step work. Rejected: append-only overrides, because the
conflicting default delegation rules would remain active. Rejected: the
installer's generated presets, because they include unreviewed provider routes,
background-subagent setup, and default worktree behavior.

The reviewed package is `oh-my-opencode-slim@2.2.8`, matching the source checkout
at `D:\Projects\Docs\oh-my-opencode-slim`. The npm registry record provides
integrity `sha512-bE4+1hAMMkxZUEt3AkI/RGgAXHgs1RhbpQw6gxadum9YDAg4zv+WIqG5Edkaw8Z8COa9NZVf2ugNNTW8Ew9GnQ==`.
Context7 was unavailable as a configured runtime MCP during this package lookup,
so this low-risk package provenance uses the source checkout and npm registry
record and is explicitly labeled as that fallback.

## Sources and Targets

| Source | Global target | Owner | Rule |
|---|---|---|---|
| `config/opencode/agent-layer.plugin.json` | `C:\Users\quang\.config\opencode\opencode.jsonc` | User/OpenCode layer | Merge only the pinned plugin entry; preserve `$schema` and unrelated fields. |
| `config/oh-my-opencode-slim/sdd-personal.json` | `C:\Users\quang\.config\opencode\oh-my-opencode-slim.json` | Framework | New plugin configuration file. |
| `prompts/oh-my-opencode-slim/sdd-personal/*.md` | `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\*.md` | Framework | New preset-specific prompt replacements. |

`opencode.jsonc` was confirmed to contain only the OpenCode schema declaration
before the Phase 4 change, with no CPA GUI ownership marker or comments. This is
the narrow supported overlay path documented by slim. The persistent runtime
must be restarted after the write.

## Active Policy

- Orchestrator: Terra `medium`, with Terra `high` as its one model fallback.
- Oracle: Sol `medium`, with Sol `high` as its one model fallback.
- Explorer, Librarian, Fixer, and Observer: M3 `none`, with M3 `thinking` as
  fallback. Designer uses the inverse primary/fallback pair.
- Council and Observer are disabled. Observer's future configuration is still
  deny-by-default so Phase 5 can only enable it intentionally.
- Multiplexer, companion, idle continuation, and slim's worktree skill are
  disabled. OpenChamber remains the sole worktree and continuation controller.
- Slim's bundled `websearch`, non-OAuth `context7`, and `gh_grep` MCPs are
  disabled. Phase 3 separately activates the reviewed OAuth Context7 MCP and
  local CodeGraph MCP; it is the only permitted path to either research source.
- Explorer, Librarian, Oracle, and Observer deny edit, shell, delegation, and
  external-directory access. They can only use their named inspection tools;
  Librarian has Context7 and permitted web retrieval, while Explorer has
  CodeGraph plus read-only local inspection permissions.
- The Orchestrator prompt limits delegation to two non-overlapping lanes and
  provides Vietnamese, action-first, non-coder communication plus OpenChamber
  advisory rules.

## Verification

Validate reviewed sources from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayer.ps1
```

After applying and restarting OpenChamber, validate the effective managed
runtime rather than the shell `opencode` wrapper:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayerRuntime.ps1
```

The runtime verifier checks plugin registration, required active agents,
disabled Observer, and the direct-tool/shell denial rules for read-only agents.
Its limitation is that it proves effective policy, not that a model will never
attempt a denied call. OpenCode enforces those policy denials at tool execution.

## Rollback

Restore only the timestamped copies of the three Phase 4 targets from
`C:\Users\quang\.local\share\opencode\framework-backups\<timestamp>`, then restart
OpenChamber and rerun `Test-AgentLayerRuntime.ps1`. Do not restore a directory,
edit `opencode.json`, or alter any OpenChamber-owned file.
