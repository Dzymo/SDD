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

Phase 5 leaves one temporary package-cache hotfix active. Restore only the
matching backup copy, then restart OpenChamber and run
`Test-AgentLayerRuntime.ps1`:

1. `C:\Users\quang\.cache\opencode\packages\oh-my-opencode-slim@2.2.8\node_modules\oh-my-opencode-slim\dist\index.js`
   from backup `20260802-204959` removes the temporary type guard.

The temporary Observer configuration was already restored from backup
`20260802-205142`; no global multimedia activation is currently active.

The package-cache patch can also be superseded by a reviewed reinstall or
version upgrade. Do not restore an entire cache directory.

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
