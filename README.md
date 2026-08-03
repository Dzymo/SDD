# Personal OpenCode Workflow Framework

Private source workspace for the global OpenCode framework used through
OpenChamber. It is not a package, marketplace extension, or distribution
project.

## Status

Phase 2's source-only framework skeleton has passed its layout and safety
verification; see `PHASE-2-FRAMEWORK-SKELETON.md`. Phase 3's Context7 OAuth and
CodeGraph MCP layer is active and runtime-verified; see
`PHASE-3-RESEARCH-LAYER.md` for scope, fallback limits, and rollback evidence.

Phase 4 applies the reviewed, non-secret source for the lean personal agent
preset: pinned slim registration, model fallbacks, prompt replacements, and
enforced read-only specialist permissions. The required agents have been
confirmed in OpenChamber after restart. See `docs/agent-layer.md` for its
controlled global targets, validation, and rollback procedure.

Phase 6 adds a project-local OpenSpec bootstrap with default `spec-driven`
configuration, generated OpenCode core commands, concise evidence templates,
and a strict-validation fixture. See `PHASE-6-OPENSPEC-PROJECT-TEMPLATE.md`.

## Layout

| Path | Purpose |
|---|---|
| `PHASE-*.md` | Phase-specific verification evidence and scope limits. |
| `docs/` | Architecture, decisions, operations, evaluation index, and rollback procedure. |
| `config/` | Future reviewed, non-secret framework configuration sources. |
| `prompts/`, `skills/`, `commands/` | Future reusable global behavior. |
| `templates/` | Project-local product, design, and OpenSpec bootstrap assets. |
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

Run the managed runtime gate after changing the MCP source, CodeGraph install,
or OpenCode version:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ResearchRuntime.ps1
```

## Validate The Agent Layer

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayer.ps1
```

This checks the source-level plugin pin, role routes and fallbacks, disabled
automation features, read-only permissions, and prompt rules. After the global
apply and OpenChamber restart, run `Test-AgentLayerRuntime.ps1` to validate the
effective managed runtime.

## Check Multimedia Readiness

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-MultimediaCapabilities.ps1
```

This confirms that GPT routes remain text-only and M3 supports image/video but
not PDF. It also verifies the enabled M3 Observer route. See
`PHASE-5-MULTIMEDIA.md` for the cache patch, structured attachment evidence,
and revalidation procedure.

## Regress Observer Handoff

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachmentRegression.ps1
```

This offline source gate protects the `image_routing: auto` preset, the
Orchestrator and Observer prompt contracts, the child-session patch record, and
the OCR smoke contract. GitHub Actions runs it on pull requests. Run the live
M3 integration smoke with `Test-ObserverAttachment.ps1` after a plugin update
or reinstall; it generates a new image with a unique visible code and verifies
that M3 returns it.

## Run Local M3 OCR Smoke

The smoke uses the managed OpenChamber CLI, never prints a credential, and
performs these preflight checks before creating an image or calling a model:

1. The managed executable and workspace exist.
2. Effective runtime config has an enabled Observer routed to
   `minimax-coding-plan/MiniMax-M3`, with the current structured-attachment
   prompt contracts loaded.
3. `auth list` reports a MiniMax credential without revealing its value.
4. M3 metadata is active and declares both image input and attachments.

Run it from `D:\Projects\SDD`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachment.ps1
```

Expected output first includes `Observer OCR preflight: PASS`, followed by
`Observer structured attachment smoke: PASS`. If the preflight fails, restore
the managed route or credential first; do not bypass it by putting a token in
this repository or changing the test to call an unmanaged CLI.

## Test OCR Preflight Failures

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachmentPreflight.ps1
```

This offline test uses a temporary mock CLI and verifies clear failures for a
missing binary or workspace, a failed or invalid runtime config, disabled
Observer, wrong M3 route, both missing prompt contracts, missing MiniMax
credential, and inactive M3 image metadata. Every negative case also verifies
that its credential sentinel is absent from the error output. It runs in the
Windows pull-request workflow and makes no provider call.

## Validate OpenSpec Template

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenSpecProjectTemplate.ps1
```

This runs strict validation against the isolated Phase 6 fixture using the
pinned `@fission-ai/openspec@1.5.0` CLI. It does not write OpenCode or
OpenChamber configuration. Copy `templates/project/` into a participating
project to begin a project-local OpenSpec workflow. Before using the generated
slash commands, install the reviewed CLI on `PATH` and restart or reload
OpenCode; see `templates/project/README.md` and the Phase 6 end-to-end record.

The copied bootstrap includes its own preflight. Run it from that project to
fail fast on a missing or version-mismatched OpenSpec CLI and to show known
generated-command dependencies that the `core` profile does not provide:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\Test-OpenSpecBootstrapPreflight.ps1
```

## Pull Request Gate

GitHub Actions runs the research schema, agent-layer source, Observer attachment
regression, copied OpenSpec bootstrap preflight using the exact `1.5.0` CLI, and
framework safety verifiers on Windows for every pull request through
`.github/workflows/research-config.yml`. Configure
`Validate research MCP schema (Windows)` as a required check in the repository's
target-branch protection rule to prevent a pull request with an invalid MCP
configuration from merging.

The workflow uses `windows-latest` so the checks run in the same PowerShell and
path environment as the managed installation.

Dependabot checks GitHub Actions weekly on Monday and opens update pull requests
when an action version or its pinned SHA changes. Review each update's upstream
release and keep the SHA pin before merging it through the Windows gate.

See `docs/operations.md` for the future source, staging, apply, check, and
rollback lifecycle.
