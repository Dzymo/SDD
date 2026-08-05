# Phase 12 Global Rollout

Date: pending execution

## Status

Phase 12 is **unstarted**. This document is an execution runbook, not rollout
evidence. Do not mark any checklist item complete until the candidate SHA,
command output, exit code, time, and artifact path have been recorded.

The rollout applies one immutable, CI-validated framework candidate to the
personal managed environment. It does not publish, deploy, tag, push, merge,
modify OpenChamber state, or perform a project release.

## Safety Boundary

- Run from `D:\Projects\SDD` on the approved candidate SHA.
- Never apply an uncommitted source worktree or reuse evidence from a different
  SHA.
- Do not include credentials, auth files, OpenChamber settings, sessions,
  Goals, relay data, Electron state, CPA GUI-managed `opencode.json`, or whole
  backup directories in the source repository or rollout record.
- `MATCH` targets are no-ops. Apply only reviewed `DRIFT` or `ABSENT` targets.
- Never manually merge JSON or copy a directory tree into global configuration.
- A failed runtime verifier is a rollback trigger. Do not rerun an apply script
  blindly.

## Required Approvals

| Checkpoint | Required approval scope | Do not proceed without |
|---|---|---|
| CI publication, if required | Candidate SHA, remote, branch, and exact `git push` or pull-request action | Explicit approval for the external write. |
| Global rollout | Candidate SHA, source/CI evidence, target list, planned scripts, backup paths, restart, provider calls/cost, and rollback plan | Explicit approval before backup, persistent write, restart, or provider request. |
| Existing-project smoke | Selected project, commit/ref, exact non-destructive command, expected result, and side effects | Explicit approval for the named project command. |
| Rollback drill | Manifest paths, named targets, restart downtime, restoration proof, and reapply plan | Explicit approval before restoring any persistent target. |

An approval is invalid if the candidate SHA, target set, planned write, provider
call, or rollback plan changes.

## 1. Pre-Write Runtime Evidence

### Preconditions

Record a pre-apply manifest that contains only sanitized metadata:

| Field | Required record |
|---|---|
| Candidate | Commit SHA, clean `git status --short`, and diff from the last CI-validated SHA. |
| Managed runtime | OpenChamber and managed OpenCode version, plugin version, and package-patch identity. |
| Active state | MCP/auth state without values, framework-owned target paths, and current SHA-256 values. |
| Diff decision | `MATCH`, `DRIFT`, or `ABSENT` for every framework-owned target. |
| Apply decision | Owner, approved script, backup location, expected after hash, verifier, restart need, and rollback action for each non-match. |

The independent pre-apply comparison is the authoritative dry-run. Do not treat
an apply script's `-WhatIf` behavior as the complete preview, and do not use
`-WhatIf` with `Apply-ResearchMcp.ps1` because it does not implement
`SupportsShouldProcess`.

### Mandatory Research Runtime Gate

The managed OpenCode version changed after the recorded Phase 3 evidence, so
run this provider-backed verification after rollout approval but before any
backup or global write:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ResearchRuntime.ps1
```

Expected terminal result:

```text
Phase 3 research runtime: PASS
```

This validates the effective OAuth Context7 and local CodeGraph MCP entries,
Context7 authentication state without printing the credential, CodeGraph index
health, and provider-backed Librarian/Explorer retrieval. It also verifies
disabled-MCP configuration and prompt contracts, but it does not prove live
model behavior in the disabled state.

### Manual Disabled-MCP Behavior Gate

Record two short, isolated managed-runtime sessions after the automated gate:

| Condition | Prompt requirement | PASS condition |
|---|---|---|
| Context7 disabled by a temporary test overlay | Ask for an external API/dependency fact. | The response says verified external evidence is unavailable or names a clear fallback. It must not invent an API claim from memory. |
| CodeGraph disabled or degraded by a temporary test overlay | Ask for an exact local path/line lookup. | The response says local evidence is unavailable or uses direct inspection. It must not infer a path or line. |

Store only a redacted transcript or result summary. The overlay and temporary
files must be removed after the check.

### Conditional Residual Gates

Run each gate below only when its managed OpenCode version, slim version,
reviewed source, active target, or relevant Phase 5 package patch changed since
the latest valid evidence. Run every corresponding verifier again after a
successful apply for any layer that actually changed.

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayerRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ExecutionVerificationRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenChamberOperatingGuideRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-UIQualityLayerRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingReleaseRuntime.ps1
```

If the managed slim package was reinstalled or updated, or the structured
attachment patch/routing changed, also run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-MultimediaCapabilities.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachment.ps1 -PreflightOnly
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ObserverAttachment.ps1
```

The full Observer test is provider-backed and passes only when it emits both
`Observer OCR preflight: PASS` and `Observer structured attachment smoke: PASS`.

### Stop Conditions

Stop before backup or write if a required command exits nonzero, a source/target
hash differs from the approved manifest, the candidate SHA changed, a provider
gate fails, a manual fallback check invents evidence, or a drifted target has no
reviewed owner and apply mechanism.

## 2. Controlled Rollout

### Apply Matrix

Close OpenChamber and CPA GUI before applying anything. Confirm no process named
`openchamber`, `cpa`, or `opencode` remains. Recompute approved source and
target hashes immediately before each apply. Execute only the rows that are
approved and remain `DRIFT` or `ABSENT`.

| Changed layer | Reviewed command | Required post-restart verifier |
|---|---|---|
| Phase 3 research MCP, references, Explorer/Librarian prompts, source-first skill | `Apply-ResearchMcp.ps1` | `Test-ResearchRuntime.ps1` and `Test-AgentLayerRuntime.ps1` |
| Phase 7 Orchestrator/Fixer/Oracle and execution skills | `Apply-ExecutionVerification.ps1` | `Test-ExecutionVerificationRuntime.ps1` |
| Phase 8 Orchestrator operating guidance | `Apply-OpenChamberOperatingGuide.ps1` | `Test-OpenChamberOperatingGuideRuntime.ps1` |
| Phase 9 Designer/Observer and `ui-quality` skill | `Apply-UIQualityLayer.ps1` | `Test-UIQualityLayerRuntime.ps1` |
| Phase 10 Orchestrator release contract and skill | `Apply-PackagingRelease.ps1` | `Test-PackagingReleaseRuntime.ps1` |
| Phase 5 cache package patch | The hash-pinned patch procedure in `docs\rollback.md` and the reviewed patch file | `Test-MultimediaCapabilities.ps1` and `Test-ObserverAttachment.ps1` |

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-ResearchMcp.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-ExecutionVerification.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-OpenChamberOperatingGuide.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-UIQualityLayer.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-PackagingRelease.ps1
```

`orchestrator.md` is a shared target for Phases 7, 8, and 10. Treat it as one
manifest target with one final reviewed source hash. Do not run multiple apply
scripts solely to rewrite a target that already matches. Similarly, record the
precise merged property when more than one layer touches
`oh-my-opencode-slim.json`.

If Phase 4 plugin-registration drift has no approved script that can restore it
without a manual merge, classify the rollout as `BLOCKED`. Do not repair that
drift during this rollout.

### Apply Evidence

For each executed script record:

| Evidence | Requirement |
|---|---|
| Decision | The pre-apply classification and reason for apply rather than no-op. |
| Backup | Timestamped `phase-<n>-*` directory outside the repository and `manifest.json` path. |
| Hashes | Source, before, and after SHA-256 for every named target. |
| Result | Command, exit code, timestamp, and any automatic restoration result. |
| Scope | Exact targets changed and any expected side effect. |

## 3. Post-Apply Runtime Smoke

Restart OpenChamber once all approved writes complete. Verify the managed binary,
not the shell wrapper:

```powershell
$managed = 'C:\Users\quang\AppData\Local\Programs\@openchamberelectron\resources\opencode-cli\opencode.exe'
& $managed debug config
& $managed agent list
```

Run every focused verifier required by an apply that actually changed a target:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ResearchRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-AgentLayerRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-ExecutionVerificationRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenChamberOperatingGuideRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-UIQualityLayerRuntime.ps1
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-PackagingReleaseRuntime.ps1
```

If Phase 5 changed, include the capability, preflight, and full OCR smoke from
the pre-write section. A runtime smoke is successful only when all applicable
commands exit `0`, plugin initialization is clean, expected agents/routes are
present, and active target hashes match reviewed sources.

Do not proceed to project smoke when a post-apply verifier fails. Restore only
the named targets from the current Phase 12 backup manifests after rollback
approval.

## 4. Final Project Smokes

### Fresh Project

Create a temporary project outside the framework source and copy only the
project bootstrap. The project must not reuse a fixture change, source-tree
dependencies, OpenChamber state, or credentials.

```powershell
$freshProject = Join-Path ([System.IO.Path]::GetTempPath()) "phase-12-fresh-project-$PID"
New-Item -ItemType Directory -Path $freshProject -ErrorAction Stop | Out-Null
Copy-Item -LiteralPath .\templates\project\* -Destination $freshProject -Recurse -ErrorAction Stop
PowerShell -ExecutionPolicy Bypass -File "$freshProject\Test-OpenSpecBootstrapPreflight.ps1"
openspec --version
```

The bare `openspec` command must report `1.5.0`. If it is absent or wrong,
stop. Do not substitute `npx` for bootstrap preflight; a global CLI install is a
separate persistent/network action that requires an updated manifest and
approval.

Create a minimal OpenSpec change through the normal OpenSpec instructions flow,
then validate it:

```powershell
openspec status --change <minimal-change-name> --json
openspec instructions <artifact-id> --change <minimal-change-name> --json
npx --yes @fission-ai/openspec@1.5.0 validate <minimal-change-name> --strict --no-interactive
```

Record the temporary path, CLI path/version, preflight output, warnings, strict
validation output, exit codes, and cleanup result. Remove the temporary project
only after evidence is captured.

### Existing Project

Run exactly one user-approved project-native smoke. Before executing it, record
the project path, commit/ref, relevant `PACKAGE.md` or OpenSpec evidence, exact
command, expected result, data side effects, and remaining uncertainty. The
command must be bounded and non-destructive. Do not infer a build, package, or
release command from the framework fixture, and do not publish, deploy, tag,
push, merge, migrate, or delete data.

## 5. Safe Rollback Drill

### Preconditions

- The rollback drill has its own explicit approval.
- The approved candidate SHA and every Phase 12 backup manifest remain
  available.
- The target list is restricted to targets changed by this rollout.
- OpenChamber and CPA GUI are closed.
- The drill record identifies baseline health checks, expected current-source
  verifier failures after restore, and the reapply commands.

### No-Drift Verification Reapply

When every approved target is `MATCH`, no normal apply creates a Phase 12 backup
manifest. Do not claim rollback is proven in that state. With a separate
approval, the one permitted verification reapply is the single framework-owned
Orchestrator target:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Apply-OpenChamberOperatingGuide.ps1
```

It is permitted only to create a `phase-8-*` file-level backup manifest for the
rollback drill. Before the command, record that the target hash matches the
reviewed source. After it, record that the target remains byte-identical. Use
that exact manifest with `Invoke-Phase12RollbackDrill.ps1`, restart OpenChamber,
and run:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-OpenChamberOperatingGuideRuntime.ps1
```

Reapply only the same Phase 8 script, restart, and rerun the verifier. This
proves the reviewed file-level backup, restore, and reapply route. It does not
prove reversal of behaviorally different content, because a no-drift reapply is
intentionally byte-identical before and after the drill.

### Restore Procedure

Use the guarded rollback command for manifests produced by Phases 3, 7, 8, 9,
and 10. First run the read-only preview, review every displayed target, then run
the restore command only after rollback approval:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Invoke-Phase12RollbackDrill.ps1 -ManifestPath '<approved-manifest.json>' -WhatIf
PowerShell -ExecutionPolicy Bypass -File .\scripts\Invoke-Phase12RollbackDrill.ps1 -ManifestPath '<approved-manifest.json>'
PowerShell -ExecutionPolicy Bypass -File .\scripts\Invoke-Phase12RollbackDrill.ps1 -ManifestPath '<approved-manifest.json>' -VerifyOnly
```

The command refuses while OpenChamber, CPA GUI, or managed OpenCode is running;
accepts only manifest targets under `C:\Users\quang\.config\opencode`; requires
the backup copy to hash to `BeforeSha256`; and verifies every restored target.
It supports both array manifests and the `entries` or single-entry shape emitted
by the reviewed apply scripts. It never restores directories. Do not use it for
the Phase 5 package-cache patch: that patch must be restored in reverse hash
order through its dedicated procedure in `docs\rollback.md`.

The offline regression gate uses an isolated temporary `USERPROFILE` and does
not inspect or modify the real global configuration. It covers a valid restore
and verification, an explicit successful restore with no runtime process, a
malformed manifest that leaves the candidate target unchanged, a tampered backup
hash, a target outside the configuration root, `-WhatIf` non-mutation, and
fail-closed rejection when each of OpenChamber, CPA GUI, or `opencode` is
active:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\scripts\Test-Phase12RollbackDrill.ps1
```

For each approved manifest entry:

1. Confirm the manifest's target is a named framework-owned file under
   `C:\Users\quang\.config\opencode` or the reviewed slim cache target.
2. If `BeforeSha256` is not `ABSENT`, hash the backup copy and require it to
   equal `BeforeSha256` before restoring it.
3. Restore only that file to its named target.
4. If `BeforeSha256` is `ABSENT`, remove only that named target if it was
   created by the rollout.
5. Hash the restored target and require it to equal `BeforeSha256`.
6. Record the manifest entry, command outcome, and restored hash.

Never restore a parent directory, OpenChamber state, CPA GUI state, credentials,
or an unrelated target. Never use `git reset --hard`, `git checkout --`, or a
whole-directory restore.

Restart OpenChamber after all named targets are restored, then run the predefined
baseline health commands. Current-source Phase 7-10 runtime verifiers hash
compare restored targets with the candidate source, so a failure for a reverted
layer can be expected. That expected failure is not restoration proof. The
decisive rollback evidence is the manifest `BeforeSha256` match plus successful
baseline managed-runtime health.

### Reapply Proof

Reapply only the same approved drift using the reviewed scripts from the apply
matrix. Restart OpenChamber and rerun every affected current-source runtime
verifier. The rollback drill passes only when:

- every restored target matched its manifest `BeforeSha256`;
- the managed runtime restarted and baseline health checks behaved as recorded;
- every re-applied target matches its expected after hash; and
- every current-source verifier for a re-applied layer exits `0`.

## 6. Final Sign-Off Checklist

Mark every row with a link or path to sanitized evidence. A missing artifact is
`BLOCKED`, not implicit PASS.

| Check | Sign-off requirement |
|---|---|
| Candidate integrity | Clean worktree, immutable candidate SHA, source gates PASS, and Windows CI PASS on that SHA. |
| Approval record | CI publication approval when needed; rollout, existing-project smoke, and rollback approvals recorded with exact scope. |
| Pre-write runtime | `Test-ResearchRuntime.ps1` PASS and manual disabled-MCP behavior evidence recorded. |
| Apply safety | Every changed target has an approved owner/script, file-level backup, and before/source/after checksum. |
| Runtime smoke | Managed config and agent list evidence captured; every verifier for an actually changed layer PASS. |
| Phase 5, if changed | Capability, preflight, and full structured-attachment OCR smoke PASS. |
| Fresh project | Bootstrap preflight PASS, bare OpenSpec version `1.5.0`, and strict minimal-change validation PASS. |
| Existing project | One approved bounded project-native smoke PASS with distinct project evidence. |
| Rollback drill | Target-level restore hashes match manifests; reapply and affected verifiers PASS. |
| Secret safety | Framework secret scan PASS and record contains no secret-bearing file or sensitive runtime state. |
| Limitations | Remaining uncertainty is explicit; source-policy evidence is not represented as future model compliance or arbitrary project correctness. |

Phase 12 may be marked **complete** only when every row is satisfied. The final
rollout record must include the candidate SHA, command outputs and exit codes,
CI URL, versions, hashes, manifests, apply/no-op decisions, project smoke
results, rollback/reapply results, approvals, and remaining limitations.
