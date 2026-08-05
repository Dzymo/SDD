# Packaging And Release

## Purpose

This layer proves a delivery artifact works separately from its source tree.
It prepares a release but does not publish, deploy, tag, push, merge, or make
any other external write automatically.

## Package Contract

Each participating project copies and completes `PACKAGE.md` from
`templates/project/`. It is the project configuration for package command
discovery: the project names its package/build command, expected artifact or
entry point, intended version, clean-environment setup, smoke command, content
checks, and rollback steps. A manifest or build file can supply evidence for a
missing field, but an agent must record the selected command rather than guess
one.

The active OpenSpec change records actual commands and results in
`verification.md` and `release.md`. The framework does not prescribe a package
manager or add a package dependency.

## Package Gate

Before a release can be ready, collect fresh evidence for every gate:

| Gate | Required evidence |
|---|---|
| Build/package | Selected package command exits 0. |
| Artifact | Expected artifact or runtime entry point exists. |
| Version | Embedded artifact version matches the intended version. |
| Clean install/run | Artifact installs or runs in a new temporary environment, then a minimal smoke command exits 0. |
| Delivered contents | Development-only files are absent; file-name and content checks find no credential material. |
| Checksum | Record a SHA-256 checksum of the exact artifact tested. |

Use a newly created directory outside the project for the smoke test. Do not
reuse the source tree's dependencies, build output, login state, or environment
files as clean-environment evidence. A matching checksum identifies an artifact;
it does not prove the artifact is safe by itself.

## Explicit Release Approval

After the package gate passes, present a release-ready summary and stop. The
user must explicitly approve all of these exact values before an external
action:

1. version;
2. release notes;
3. target or environment;
4. known warnings;
5. rollback plan; and
6. exact external action, such as a named publish, deploy, tag, push, or merge.

Record the approval text, person, and date in `release.md`. Passing a build,
asking to “release”, or an approval for different values is not approval. Any
change to the approved version, notes, target, warnings, rollback plan, or
external action invalidates the approval and requires a new one.

Only after this record exists may the approved exact external action run. Record
its command, exit code, result identifier or URL where available, and
post-release smoke result. If it fails, report `BLOCKED`, follow the recorded
rollback plan when the user directs it, and retain the active OpenSpec change.

## OpenSpec Archive And Rollback

Archive only after the external action and post-release smoke both succeed. Run
normal strict OpenSpec validation first, then use the platform-native command:

```powershell
openspec validate <change-name> --strict --no-interactive
openspec archive <change-name>
```

Do not bypass validation or archive a failed, cancelled, or merely
release-ready change. The project-specific rollback procedure remains in
`PACKAGE.md` and is copied into the approved `release.md`; it must state how to
restore the previous known-good delivery without deleting unrelated data.
