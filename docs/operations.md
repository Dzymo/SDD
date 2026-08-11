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
change artifacts there, and use the five adapted `/opsx-*` commands. They
interview the user in-session and maintain project files themselves; the user
must not be asked to fill artifacts manually. It has no global configuration
target or apply operation. The project commands call
bare `openspec`; install `@fission-ai/openspec@1.5.0` on `PATH`, confirm its
version, and restart or reload OpenCode after copying the bootstrap. The pinned
one-off `npx` form is not a replacement for that executable when using slash
commands.

Before first slash-command use in the copied project, run its preflight:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\Test-OpenSpecBootstrapPreflight.ps1
```

It fails for an unavailable or version-mismatched CLI, a missing command, or a
command that loses the session-first/next-step advisory contract. It also warns,
with source file and line, about unavailable command or skill dependencies. It
does not add commands or skills to compensate for the OpenSpec `core` profile.

Phase 10 adds project-local package and release evidence. Complete the copied
`PACKAGE.md` before selecting package, clean-smoke, content-check, checksum,
or rollback commands. See `docs/packaging-and-release.md`. This phase does not
perform an external release action or apply global configuration without a
separate explicit user approval. Its offline source evaluator and source
contracts are complete; the historic 2026-08-04 record of the controlled
activation and managed-runtime verification is retained for provenance, and
the managed-runtime verification is a required residual gate that has not
been re-run in this update.

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
| Managed-runtime validation command | `scripts\Test-ResearchRuntime.ps1` (config inspection plus prompt-based behavioral assertion; live model behavior is a manual gate, not a runtime-verified claim). |
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

Validate the Phase 7 execution and truthful-completion source contracts:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ExecutionVerification.ps1
```

This evaluator accepts only records with a complete task brief and M3 Fixer
route. It requires red-green evidence for its bug fixture, requires Oracle
assumption review after two failed repairs, and rejects any `PASS` record with a
nonzero required command exit code. It is an offline framework check, not proof
that an application's commands have passed.

To activate all Phase 7 framework-owned prompts and skills, first close
OpenChamber and CPA GUI, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-ExecutionVerification.ps1
```

The script validates source contracts, creates a timestamped file-level backup
and manifest, verifies every copied target hash, and restores all changed
targets if any write or manifest step fails. Restart OpenChamber, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ExecutionVerificationRuntime.ps1
```

The runtime step is a required residual gate for Phase 7 and has not been
re-run in this update. The runtime verifier hash-compares the active global
Orchestrator, Fixer, and Oracle prompts and the systematic-debugging and
verification-before-completion skills against their reviewed sources and
checks the Phase 7 prompt rules; a hash mismatch is a fail-closed condition
that means a manual edit drifted an active target from the reviewed source.

Validate the Phase 8 OpenChamber operating-guide source contracts:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenChamberOperatingGuide.ps1
```

This evaluator is offline and read-only. It tests adaptive interview fast/deep
paths, the recommendation matrix, worktree requirements for writing Goals,
read-only Goal limits, material-decision and budget pause behavior, the
`ready for release` boundary, the no-silent-Goal prompt contract, and the
invariant that OpenChamber Session Goals are the only automatic parent-session
continuation controller. It does not arm a Goal or alter OpenChamber settings.

After controlled Phase 8 prompt activation and an OpenChamber restart, run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenChamberOperatingGuideRuntime.ps1
```

The runtime smoke checks the managed OpenCode plugin and active global
Orchestrator prompt. It is read-only and does not arm a Goal or create a
worktree. The runtime verifier hash-compares the active global Orchestrator
prompt with the reviewed Phase 8 source before checking the required rule
substrings; a hash mismatch is a fail-closed condition that means a manual
edit drifted the active prompt from the reviewed source. The runtime step
is a required residual gate for Phase 8 and has not been re-run in this
update.

Validate the Phase 11 evaluation and failure drills:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-EvaluationFailureDrills.ps1
```

This offline source gate derives the verdict for all 21 required failure drills
and checks the related Orchestrator, Fixer, Oracle, research-skill, and preset
contracts. It does not call a provider, modify global configuration, create a
worktree, or perform an external action. See `docs\evaluation-and-failure-drills.md`
for its exact scope and limitations.

Validate the Phase 9 UI-quality source contracts:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-UIQualityLayer.ps1
```

This evaluator is offline and read-only. It requires product/design/surface
authority, desktop/mobile/browser/accessibility evidence, and a closed fresh
screenshot review, but it distinguishes that review-ready state from explicit
user visual approval. It rejects synthetic-score proof and does not invoke a
browser, install Impeccable, or change global configuration.

To activate only the reviewed Phase 9 Designer/Observer prompts, Designer skill
permission, and `ui-quality` skill, first close OpenChamber and CPA GUI, then
run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-UIQualityLayer.ps1
```

The apply script backs up only `oh-my-opencode-slim.json`, the Designer and
Observer prompts, and the new skill file under a `phase-9-*` protected backup
directory. It merges only `presets.sdd-personal.designer.skills` in the JSON
target and restores changed files on a failed post-write check. Restart
OpenChamber, then verify the effective managed runtime with:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-UIQualityLayerRuntime.ps1
```

The runtime step is a required residual gate for Phase 9 and has not been
re-run in this update. The runtime verifier hash-compares the active global
Designer/Observer prompts and the `ui-quality` skill against their reviewed
sources and checks the Phase 9 prompt rules; a hash mismatch is a fail-closed
condition that means a manual edit drifted an active target from the reviewed
source.

Validate the Phase 10 package and release source contracts:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingRelease.ps1
```

This offline source gate packs a local dependency-free fixture, installs it in
a new temporary directory with install scripts disabled, runs its smoke entry
point, verifies its SHA-256 and delivered contents, and tests release approval
and archive scenarios. It does not contact a registry, publish, deploy, tag,
push, merge, or modify global OpenCode configuration.

To activate only the reviewed Orchestrator release contract and
`package-and-release` skill, first close OpenChamber and CPA GUI, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-PackagingRelease.ps1
```

It makes a timestamped `phase-10-*` file-level backup and SHA-256 manifest for
only those two global targets, restores changed targets on a failed write or
hash check, and never performs a release. Restart OpenChamber, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingReleaseRuntime.ps1
```

The runtime step is a required residual gate for Phase 10 and has not been
re-run in this update. The runtime verifier hash-compares the active global
Orchestrator prompt and the `package-and-release` skill against their
reviewed sources and checks the Phase 10 prompt rules; a hash mismatch is a
fail-closed condition that means a manual edit drifted an active target
from the reviewed source.

Use the controlled activation script only after OpenChamber and CPA GUI have
stopped:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-OpenChamberOperatingGuide.ps1
```

It refuses to run if an OpenChamber, CPA GUI, or managed OpenCode process is
active. On apply it copies only the framework-owned Orchestrator prompt and
writes a timestamped backup plus SHA-256 manifest under the protected backup
root.

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
OpenChamber binary is the active runtime. The runtime verifier inspects the
read-only agents' permission denials for `edit`, `bash`, `task`, and
`external_directory` equivalently across Explorer, Librarian, Oracle, and
Observer. The runtime step is a required residual gate for Phase 4 and has
not been re-run in this update; the last re-run was on 2026-08-02 before
Observer was added to the verifier.

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

For a completed change on Windows, the adapted `/opsx-archive` prompt invokes
`openspec archive <change-name>` directly and does not create archive folders
manually. See the Phase 6 end-to-end validation record for the core-profile
limitations and their workarounds.

## Pull Request Validation

`.github/workflows/research-config.yml` runs the research schema, agent-layer,
execution/verification, OpenChamber operating-guide, UI-quality layer, package
and release fixture, evaluation and failure drills, Observer attachment regression, Observer OCR preflight
negative suite, copied OpenSpec bootstrap
preflight with `@fission-ai/openspec@1.5.0`, and framework source-safety
verifiers on Windows for every pull request. The bootstrap job installs the
exact CLI, asserts its version, copies `templates\project` into a fresh
runner-temporary directory, then runs the copied preflight script.

The pull-request workflow also installs pinned `opencode-ai` and slim packages
under `RUNNER_TEMP`, applies the reviewed package hash chain, and runs
`Test-ManagedRuntimeIsolated.ps1`. That isolated host smoke invokes the Phase 4
and Phase 7-10 managed-runtime verifiers with temporary config, data, cache, and
state paths. It proves plugin initialization and effective source contracts but
does not read or write active global targets. Provider-backed
`Test-ResearchRuntime.ps1`, full Observer OCR, and post-apply verification of
the actual global configuration remain local Phase 12 gates rather than hosted
CI jobs. Phase 12 global rollout is **complete** for candidate
`b75043d6097d12ac52c5bbbc3224f316c3243961`; its managed-runtime and
provider-backed evidence is recorded in `PHASE-12-GLOBAL-ROLLOUT.md`. A future
framework candidate or managed-runtime change requires a new local Phase 12
evidence run before its approved global write.

The `main` branch requires the `Validate research MCP schema (Windows)` check
before merge. Branch protection also requires branches to be current before
merge and applies to administrators. Verify the live repository setting with:

```powershell
gh api repos/Dzymo/SDD/branches/main/protection
```

The workflow file does not configure repository-level merge permissions by
itself; retain this GitHub branch-protection setting when changing the workflow
or its required job name.

## Action Update Cadence

`.github/dependabot.yml` checks all GitHub Actions weekly on Monday. Review a
Dependabot pull request against the upstream release, retain the full commit SHA
pin, and require the Windows check before merging it.
