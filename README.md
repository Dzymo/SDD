# Personal OpenCode Workflow Framework

Private source workspace for the global OpenCode framework used through
OpenChamber. It is not a package, marketplace extension, or distribution
project.

## Status

Phase 2 provides the source skeleton and its safety documentation. Phase 3 now
adds a non-secret research-MCP schema and its local validation fixtures. It does
not install a plugin, write a global OpenCode configuration file, or modify
OpenChamber.

## Layout

| Path | Purpose |
|---|---|
| `docs/` | Architecture, decisions, operations, evaluation index, and rollback procedure. |
| `config/` | Future reviewed, non-secret framework configuration sources. |
| `prompts/`, `skills/`, `commands/` | Future reusable global behavior. |
| `templates/` | Future project and OpenSpec bootstrap assets. |
| `scripts/` | Safe repository checks and future lifecycle tooling. |
| `evals/` | Reproducible evaluation evidence. |
| `fixtures/` | Small, isolated verification inputs. |

## Operating Rules

1. `PLAN.md` is the implementation source of truth.
2. Keep product facts and OpenSpec change history in each participating project.
3. Never copy provider credentials, OpenChamber settings, sessions, relay data,
   runtime state, or protected backups into this workspace.
4. Do not apply a global configuration change until its owner, target, backup,
   validation command, and rollback have been recorded.

## Check The Skeleton

Run from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-FrameworkSkeleton.ps1
```

The check validates the required layout, permits only the reviewed source schema
under `config/`, and scans committed text for common credential markers. It does
not read any user configuration directory.

## Validate The Research Schema

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ResearchConfigSchema.ps1
```

The validator accepts the approved Context7 OAuth and local CodeGraph MCP
fragment, and rejects an authentication header, altered CodeGraph command, and
non-OAuth Context7 endpoint.

## Pull Request Gate

GitHub Actions runs `Test-ResearchConfigSchema.ps1` and
`Test-FrameworkSkeleton.ps1` on Ubuntu and Windows for every pull request
through `.github/workflows/research-config.yml`. Configure both
`Validate research MCP schema (Ubuntu)` and `Validate research MCP schema
(Windows)` as required checks in the repository's target-branch protection rule
to prevent a pull request with an invalid MCP configuration from merging.

See `docs/operations.md` for the future source, staging, apply, check, and
rollback lifecycle.
