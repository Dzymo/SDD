---
name: package-and-release
description: Package an application and prepare or execute a release only with clean-environment evidence and explicit user approval. Use when a user asks to package, publish, deploy, tag, release, or archive an OpenSpec change.
---

# Package And Release

## Establish The Package Contract

1. Read the project's `PACKAGE.md` before choosing package, artifact, smoke, or
   content-check commands. It is the project configuration for this workflow.
2. If it is missing or incomplete, discover the supported project command from
   its declared tooling (for example, package manifest or build configuration),
   interview the user only for unresolved material release facts, then create or
   update `PACKAGE.md` yourself. Never ask the user to fill a project file
   manually, and do not invent a publish or deploy command.
3. Keep the command, intended version, expected artifact, clean-environment
   smoke check, content exclusions, and rollback procedure in
   `<changeRoot>/verification.md` and `<changeRoot>/release.md`, where
   `changeRoot` comes from `openspec status --change <name> --json` for a local
   change or `openspec status --change <name> --store <id> --json` for the
   selected store. Preserve the same store ID on later instructions,
   validation, and archive commands.

## Package Gate

Do not mark a package ready until fresh evidence shows all of the following:

- the package/build command exited 0;
- the expected artifact exists and embeds the intended version;
- the artifact installs or runs in a newly created temporary environment;
- the minimal smoke command exited 0 there;
- the delivered contents contain no development-only or sensitive files and
  content checks found no credential material;
- a SHA-256 checksum, exact command output, and known limitations are recorded.

Package success is local evidence only. It is not permission to publish,
deploy, push, tag, merge, or make another external write.

A Session Goal may prepare the release by building, packaging, inspecting the
artifact, running clean-environment smoke checks, calculating checksums,
drafting release notes, collecting warnings, and preparing rollback steps. Its
terminal state is `ready for release`. It must stop before publish, deploy, tag,
push, merge, purchase, production mutation, or post-release archive.

## Release Gate

When all package evidence is complete, present a concise release-ready summary
and stop for an explicit user approval record. The record must approve the
exact version, release notes, target or environment, known warnings, rollback
plan, and exact external action. A previous approval is invalid if any of
those values changes.

Never infer approval from a request to “release”, a passing build, a prior
conversation, or a prepared `release.md`. Never perform an external release
action while approval is missing, ambiguous, or scoped to different values.

Run the exact approved external action outside the Goal boundary. Do not resume
or widen a Goal to cross the release boundary.

After an approved external command succeeds, record its command, exit code,
result identifier or URL when available, and post-release smoke result. Run
normal OpenSpec strict validation and archive only after that successful
release record. Do not bypass archive validation. If the external action or
post-release check fails, report `BLOCKED`, preserve the active change, and use
the recorded rollback plan; do not archive it.

## Archive Branch Decision

Release applicability is decided from real evidence, not from a default
expectation. A change is release-applicable when it adds or updates
`PACKAGE.md`, when `proposal.md`, `design.md`, or `tasks.md` describe package,
deploy, publish, container/build artifact, tag, push, merge, release, or any
other external write, or when `release.md` already records an external action
or result. In every such case the release branch is mandatory and cannot be
downgraded to no-external-release in order to skip approval or post-release
gates.

For a genuine no-external-release change, the same archive prompt must still
verify completed tasks/artifacts, full requirement coverage, fresh focused
validation with exit code `0`, and strict `openspec validate` with exit code
`0`, and it must record `releaseApplicable: false` plus a short reason in
`verification.md`. User confirmation cannot bypass any gate, and a fake
release approval or result is forbidden. Both branches converge on the same
Phase 1 archive command (one of the four `--skip-specs --yes`/`--yes`
variants keyed by store vs local root and sync vs unsync).
