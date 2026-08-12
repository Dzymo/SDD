# Packaging And Release

## Purpose

This layer proves a delivery artifact works separately from its source tree.
It prepares a release but does not publish, deploy, tag, push, merge, or make
any other external write automatically.

## Package Contract

Each participating project receives `PACKAGE.md` from `templates/project/`.
The agent inspects project tooling, interviews the user only for unresolved
material release facts, and completes the file itself; the user is never asked
to edit it manually. It records the package/build command, expected artifact or
entry point, intended version, clean-environment setup, smoke command, content
checks, and rollback steps rather than guessing them.

The active OpenSpec change records actual commands and results in
`<changeRoot>/verification.md` and `<changeRoot>/release.md`, where
`changeRoot` comes from OpenSpec status. The framework does not prescribe a
package manager or add a package dependency.

Release plans may represent either a prerelease such as `v1.2.0-rc.1` or a
stable version such as `v1.2.0`. The plan records an explicit Boolean
`prerelease`; it must be `true` exactly when the version has an `-rc.N` suffix.
Packaging embeds this value in both manifests, and the release workflow adds
GitHub's prerelease flag only when the approved plan requires it. A stable
promotion may intentionally package the same immutable target SHA as an
accepted RC, but that payload decision and any excluded later commits must be
stated in `PACKAGE.md`, release notes, and known warnings.

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

## Goal Boundary

A Session Goal may prepare the release by building or packaging, inspecting the
artifact, running clean-environment smoke checks, calculating checksums,
drafting release notes, collecting known warnings, and preparing rollback
steps. Its terminal state is `ready for release`.

The Goal must stop before publish, deploy, tag, push, merge, purchase,
production mutation, or post-release archive. The exact approved external action
runs outside the Goal boundary in normal conversation after explicit approval.
Do not resume or widen a Goal to cross this boundary.

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

Only after this record exists may the approved exact external action run outside
the Goal boundary. Record
its command, exit code, result identifier or URL where available, and
post-release smoke result. If it fails, report `BLOCKED`, follow the recorded
rollback plan when the user directs it, and retain the active OpenSpec change.

## OpenSpec Archive And Rollback

Release applicability is decided from real evidence (added or updated
`PACKAGE.md`, or `proposal.md`/`design.md`/`tasks.md` specifying package,
deploy, publish, container/build artifact, tag, push, merge, release, or any
other external write, or an existing `release.md` with an external action or
result). The release-applicable branch is mandatory whenever any of those
indicators is present; it cannot be downgraded to no-external-release to bypass
the approval and post-release gates.

For a release-applicable change, archive only after the external action and
post-release smoke both succeed. Run normal strict OpenSpec validation first.
If `/opsx-sync` already merged the delta, skip spec application during archive;
otherwise let archive apply it exactly once:

```powershell
openspec validate <change-name> --strict --no-interactive
openspec archive <change-name> --skip-specs --yes
# Or, when the delta has not been synced:
openspec archive <change-name> --yes
```

For a selected store, preserve the same explicit store ID on validation and on
either archive branch: `--store <store-id>`. Local commands omit `--store`.

A genuine no-external-release change still requires completed tasks/artifacts,
full requirement coverage, fresh focused validation with exit code `0`, strict
OpenSpec validation with exit code `0`, and a recorded `releaseApplicable:
false` plus reason in `verification.md`. User confirmation cannot bypass any
gate, and a fake release approval or result is forbidden.

Do not bypass validation or archive a failed, cancelled, or merely
release-ready change. The project-specific rollback procedure remains in
`PACKAGE.md` and is copied into the approved `release.md`; it must state how to
restore the previous known-good delivery without deleting unrelated data.
