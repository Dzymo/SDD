# Rollback

## Phase 2 Result

Phase 2 makes no global configuration writes. Its rollback is therefore a
source-only change: remove or revise the affected framework source through
normal file history, then rerun `scripts/Test-FrameworkSkeleton.ps1`.

## Phase 3 Research Layer

The initial complete Phase 3 backup is
`C:\Users\quang\.local\share\opencode\framework-backups\phase-3-20260803-171732`.
Restore only its listed copies of:

1. `C:\Users\quang\.config\opencode\opencode.jsonc`
2. `C:\Users\quang\.config\opencode\oh-my-opencode-slim.json`
3. `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\explorer.md`
4. `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\librarian.md`

The `source-first-research` skill did not exist before Phase 3, so remove only
`C:\Users\quang\.config\opencode\skills\source-first-research\SKILL.md` if
rolling back the whole layer. Restart OpenChamber, then run `opencode mcp list`
and `Test-AgentLayerRuntime.ps1`. OAuth credentials are not in the backup; run
`opencode mcp logout context7` separately only when revoking the Context7 login
is intended.

## Phase 4 Agent Layer

Phase 4 changes only these global files, after file-level backup:

1. `C:\Users\quang\.config\opencode\opencode.jsonc`
2. `C:\Users\quang\.config\opencode\oh-my-opencode-slim.json`
3. `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md`
4. `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\explorer.md`
5. `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\librarian.md`

Restore only the matching backup copies from the Phase 4 timestamp directory,
restart OpenChamber, and run `Test-AgentLayerRuntime.ps1`. If a target did not
exist before Phase 4, remove only that named framework-owned target. Never
restore the parent directory and never alter `opencode.json` or OpenChamber
state.

## Phase 5 Multimedia Layer

Phase 5 presently has two temporary package-cache hotfixes active. They modify
the same bundled file in a strict hash chain:

1. Official npm `dist\index.js`:
   `816D84ABF3DD5923F56DF2C52F3AB7149B46654C3FBBDE9DF8760D22823DEDFC`.
2. The disabled-tools type guard produces:
   `3D70AB6200A5AF7718BFFCF229D985A9C8E2925BA0AD7676046C274E57E65CC5`.
3. The structured attachment patch produces:
   `6E6A67DF17820B6E3DCAE43BCAFD6DEA2705666A161227769AE32E2576A8989A`.

The only runtime target is
`C:\Users\quang\.cache\opencode\packages\oh-my-opencode-slim@2.2.8\node_modules\oh-my-opencode-slim\dist\index.js`.
The npm package does not publish separate distribution files for the affected
hook or tool code. Therefore, roll back in reverse order rather than treating
the patches as independent files:

1. Close OpenChamber and CPA GUI. Follow the file-level rollback block in
   `patches\oh-my-opencode-slim-2.2.8-observer-attachment.patch`, using the
   exact timestamped backup directory printed during its pre-apply step. It
   verifies the current 6E6A... hash and backup 3D70... hash before restoring.
   This disables structured image handoff while retaining the type guard.
2. Only after the target is back at 3D70..., restore the disabled-tools backup
   `C:\Users\quang\.local\share\opencode\framework-backups\20260802-204959`
   according to `patches\oh-my-opencode-slim-2.2.8-disabled-tools.patch` if the
   type guard must also be removed. Verify the resulting 816D... hash.
3. Restart OpenChamber and run `Test-AgentLayerRuntime.ps1`. The Observer smoke
   must fail closed after step 1 because its required 6E6A... hash is absent.

The temporary Observer configuration JSON was already restored from backup
`20260802-205142`; the global preset no longer carries a temporary
`disabled_tools` modification. With both runtime patches active, the structured
attachment route is the live multimedia activation.

A reviewed reinstall or version upgrade may supersede both cache patches. Safe
reapply is baseline 816D... to disabled-tools 3D70... to structured attachment
6E6A..., with a fresh file-level backup before each write. Stop on any other
hash, re-derive the patch against that artifact, and never restore an entire
cache directory.

## Phase 8 OpenChamber Operating Guide

`Apply-OpenChamberOperatingGuide.ps1` changes only
`C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md`.
Its timestamped `phase-8-*` backup directory contains a copy of that prompt and
a `manifest.json` with before/source/after SHA-256 values.

To roll back, close OpenChamber and CPA GUI, restore only the backed-up
`orchestrator.md` to that same target, restart OpenChamber, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayerRuntime.ps1
```

Do not restore the backup directory, modify `opencode.json`, or alter
OpenChamber settings, sessions, Goals, or worktrees. A pre-Phase-8 prompt will
intentionally fail `Test-OpenChamberOperatingGuideRuntime.ps1`; use that result
only to confirm the new advice is no longer active.

## Phase 7 Execution And Verification

`Apply-ExecutionVerification.ps1` changes only the framework-owned
Orchestrator, Fixer, and Oracle prompts plus the `systematic-debugging` and
`verification-before-completion` skills. Its `phase-7-*` backup directory
contains each pre-existing target and a SHA-256 manifest.

To roll back, close OpenChamber and CPA GUI, restore only the named targets
from that manifest, remove only a target whose manifest records `ABSENT` before
apply, restart OpenChamber, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ExecutionVerificationRuntime.ps1
```

Do not restore a parent directory, edit `opencode.json`, or alter OpenChamber
state. A pre-Phase-7 target intentionally fails the Phase 7 runtime verifier.

## Phase 9 UI Quality Layer

`Apply-UIQualityLayer.ps1` changes only these framework-owned targets:

1. `C:\Users\quang\.config\opencode\oh-my-opencode-slim.json` by merging only
   `presets.sdd-personal.designer.skills`.
2. `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\designer.md`.
3. `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\observer.md`.
4. `C:\Users\quang\.config\opencode\skills\ui-quality\SKILL.md`.

Its timestamped `phase-9-*` backup includes existing target copies and a
manifest with before/source/after SHA-256 values. To roll back, close
OpenChamber and CPA GUI, restore only each existing backed-up file to its named
target, and remove only a named target whose manifest records `ABSENT` before
the apply. Restart OpenChamber, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayerRuntime.ps1
```

Do not restore a directory, modify `opencode.json`, or alter OpenChamber state.

## Phase 10 Packaging And Release

`Apply-PackagingRelease.ps1` changes only these framework-owned global targets:

1. `C:\Users\quang\.config\opencode\oh-my-opencode-slim\sdd-personal\orchestrator.md`.
2. `C:\Users\quang\.config\opencode\skills\package-and-release\SKILL.md`.

Its timestamped `phase-10-*` backup directory records each pre-existing target
and before/source/after SHA-256 values in `manifest.json`. To roll back the
framework behavior, close OpenChamber and CPA GUI, restore only each named
target from that manifest, remove only a named target whose prior hash is
`ABSENT`, restart OpenChamber, then run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingReleaseRuntime.ps1
```

This restores framework instructions only; it does not reverse an external
release. For a released project, use the project-specific rollback procedure
recorded in its approved `PACKAGE.md` and `release.md`, with separate user
approval for any external action. Never restore directories or OpenChamber
state.

## Future Global Configuration Rollback

Use this procedure only after a later phase has identified a supported owner
and a specific affected file.

1. Quit OpenChamber and CPA GUI before changing persistent global configuration.
2. Back up only the approved target to
   `C:\Users\quang\.local\share\opencode\framework-backups\<timestamp>` and
   record its SHA-256 before the write.
3. If validation fails, restore only that target from the same timestamped
   backup. Do not restore directories wholesale.
4. Validate with the managed OpenChamber binary:

```powershell
$managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe'
& $managed debug config
& $managed agent list
```

5. Run the focused behavior check for the changed component, then restart
   OpenChamber and CPA GUI because persistent configuration is not hot-reloaded.

Never edit or restore CPA GUI-managed `opencode.json` and its state sidecar,
OpenChamber `settings.json`, `managed-opencode`, `agent-tool`, sessions, goals,
relay files, or Electron profile data through this framework.
