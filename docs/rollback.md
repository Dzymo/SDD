# Rollback

## Phase 2 Result

Phase 2 makes no global configuration writes. Its rollback is therefore a
source-only change: remove or revise the affected framework source through
normal file history, then rerun `scripts/Test-FrameworkSkeleton.ps1`.

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
