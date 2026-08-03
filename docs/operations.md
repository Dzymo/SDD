# Operations

## Current State

Phase 3 applies the reviewed Context7 OAuth MCP, local CodeGraph MCP, hidden
CodeGraph reference, source-first research skill, and scoped specialist MCP
access. Its source/target mapping, runtime evidence, backup manifests, and
fallback limits are recorded in `PHASE-3-RESEARCH-LAYER.md`.
Phase 4 adds a controlled global agent-layer apply with the exact source and
target mapping in `docs/agent-layer.md`.
Phase 6 adds only a project-local OpenSpec bootstrap. Copy
`templates\project\` into a participating project, keep product and active
change artifacts there, and use the generated `/opsx-*` commands. It has no
global configuration target or apply operation. The generated commands call
bare `openspec`; install `@fission-ai/openspec@1.5.0` on `PATH`, confirm its
version, and restart or reload OpenCode after copying the bootstrap. The pinned
one-off `npx` form is not a replacement for that executable when using slash
commands.

Before first slash-command use in the copied project, run its preflight:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\Test-OpenSpecBootstrapPreflight.ps1
```

It fails for an unavailable or version-mismatched CLI and warns, with source
file and line, about unavailable generated command or skill dependencies. It
does not add commands or skills to compensate for the OpenSpec `core` profile.

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
back into this repository. Phase 3 uses the reviewed
`Apply-ResearchMcp.ps1` merge path instead: it validates sources, creates a
fresh file-level backup and manifest, then applies only the named targets.

## Apply Contract

An apply operation requires all of the following before any write:

| Required evidence | Current Phase 3 result |
|---|---|
| Specific target and owner | Recorded in `PHASE-3-RESEARCH-LAYER.md`. |
| Supported write mechanism | `scripts\Apply-ResearchMcp.ps1` merges only reviewed non-secret sources. |
| External protected backup | `phase-3-20260803-171732` manifest records the initial file-level state. |
| Managed-runtime validation command | `scripts\Test-ResearchRuntime.ps1`. |
| File-level rollback path | `docs\rollback.md` Phase 3 procedure. |

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

Validate the Phase 4 source before the controlled apply:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayer.ps1
```

After applying the three approved files and restarting OpenChamber, run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayerRuntime.ps1
```

Do not use the shell `opencode` wrapper as proof for this check: the managed
OpenChamber binary is the active runtime.

Validate the offline Observer attachment regression contract before a pull
request or source change:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachmentRegression.ps1
```

After an update, reinstall, or media-routing change, run the live managed
runtime smoke as well:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachment.ps1
```

The smoke runs its preflight before generating its OCR image or calling either
model route. It checks the managed executable and workspace, effective
Orchestrator/Observer prompt contracts, enabled Observer M3 route, MiniMax
credential presence via `auth list`, and active M3 image-attachment metadata.
The test captures these command outputs and only reports pass/fail; it does not
print a credential. Expected output is:

```text
Observer OCR preflight: PASS
Observer structured attachment smoke: PASS
```

If preflight reports a missing MiniMax credential, authenticate through the
managed CLI's `auth login` flow. Do not add an API key to this repository, a
test argument, or a shell command. If route metadata or effective prompts are
wrong, restore the reviewed global plugin configuration and restart OpenChamber
before retrying.

Run the offline negative suite after changing preflight behavior:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachmentPreflight.ps1
```

It uses a temporary mock managed CLI to force each failure branch: missing
binary/workspace, failed or malformed effective config, disabled Observer,
wrong Observer model, absent Orchestrator or Observer contract, absent MiniMax
credential, and inactive M3 metadata. Each assertion requires the dedicated
error text and verifies that a credential sentinel supplied by the mock does
not appear in the error output. It does not call a provider or inspect an actual
credential.

The source gate runs in GitHub Actions and checks that the generated OCR fixture,
the exact return-code assertion, prompt contracts, preset, and runtime-patch
record cannot silently regress. The live smoke requires the local managed
OpenCode binary and M3 route, so it is intentionally not a hosted CI job.

## OpenSpec Template Check

Run the strict fixture validation from the framework root:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenSpecProjectTemplate.ps1
```

The script invokes the pinned `@fission-ai/openspec@1.5.0` CLI against only
`fixtures\phase-6\valid-project`. It needs npm registry access on a cold cache
and performs no global write. For a participating project, run strict
validation on its real active change before verification or archive:

```powershell
npx --yes @fission-ai/openspec@1.5.0 validate <change-name> --strict --no-interactive
```

For a completed change on Windows, invoke `openspec archive <change-name>`
directly. The generated core `/opsx-archive` prompt uses a POSIX `mkdir -p`
step that emits a PowerShell `ResourceExists` error when the archive directory
already exists. See the Phase 6 end-to-end validation record for the other core
profile limitations and their workarounds.

## Pull Request Validation

`.github/workflows/research-config.yml` runs the research schema, agent-layer,
Observer attachment regression, Observer OCR preflight negative suite, copied
OpenSpec bootstrap preflight with `@fission-ai/openspec@1.5.0`, and framework
source-safety verifiers on Windows for every pull request. The bootstrap job
installs the exact CLI, asserts its version, copies `templates\project` into a
fresh runner-temporary directory, then runs the copied preflight script.
Repository branch protection must require `Validate research MCP schema (Windows)`
before merge; the workflow file does not change repository-level merge
permissions by itself.

## Action Update Cadence

`.github/dependabot.yml` checks all GitHub Actions weekly on Monday. Review a
Dependabot pull request against the upstream release, retain the full commit SHA
pin, and require the Windows check before merging it.
