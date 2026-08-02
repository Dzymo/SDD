# Operations

## Current State

There are no deployable global configuration files in this repository. Phase 3
contains only a source schema for the approved research MCP fragment; it does
not authorize generation, installation, or a global configuration write.

## Future Configuration Lifecycle

1. Author a non-secret source under the appropriate `config/` subdirectory and
   record provenance and the intended global target in `docs/decisions.md`.
2. Generate a reviewable staging copy outside the source tree. Generated output
   must contain only the approved source files and an itemized manifest of
   source path, target path, and SHA-256.
3. Review the staged diff. Do not stage provider configuration, authentication,
   OpenChamber settings, session state, relay data, or runtime files.
4. Identify the target file's owner and supported write path. Stop if the owner
   is unknown or the target is CPA GUI- or OpenChamber-managed.
5. Create a timestamped, file-level protected backup outside this repository,
   record its SHA-256, then apply the single reviewed change through the owner.
6. Validate with the managed OpenChamber OpenCode binary using the commands
   appropriate to the change, such as `debug config`, `agent list`, model
   inspection, and the focused behavior check.
7. Record the result and the after-change checksum. If validation fails,
   restore only the affected file from the same backup and validate again.

## Generation Contract

Generation is a controlled transformation from reviewed framework source to a
temporary staging directory. It is not a copy of the live global configuration
back into this repository. Until a phase adds a concrete non-secret config
source and manifest, no generation command is authorized or needed.

## Apply Contract

An apply operation requires all of the following before any write:

| Required evidence | Current Phase 2 result |
|---|---|
| Specific target and owner | Known in the Phase 0 baseline, but no target is approved. |
| Supported write mechanism | Not established for a framework change. |
| External protected backup | Procedure defined; no backup created. |
| Managed-runtime validation command | Procedure defined in `docs/rollback.md`. |
| File-level rollback path | Procedure defined in `docs/rollback.md`. |

No blanket directory copy, `git reset`, `git checkout`, or OpenChamber runtime
restore is permitted as an apply or rollback operation.

## Routine Check

Run this from the repository root after a skeleton or source-layout change:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-FrameworkSkeleton.ps1
```

The verifier is local and read-only. It neither accesses nor alters global
OpenCode or OpenChamber configuration.

Validate the reviewed research-MCP source before staging it:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ResearchConfigSchema.ps1
```

The schema permits only the Context7 OAuth endpoint and the local
`codegraph serve --mcp` command. It rejects fields that could carry
authentication or alter the approved server definitions.

## Pull Request Validation

`.github/workflows/research-config.yml` runs the research schema and framework
source-safety verifiers on Windows for every pull request. Repository branch
protection must require `Validate research MCP schema (Windows)` before merge;
the workflow file does not change repository-level merge permissions by itself.

## Action Update Cadence

`.github/dependabot.yml` checks all GitHub Actions weekly on Monday. Review a
Dependabot pull request against the upstream release, retain the full commit SHA
pin, and require the Windows check before merging it.
