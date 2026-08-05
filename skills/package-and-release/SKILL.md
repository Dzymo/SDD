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
   record the proposed command and artifact, and do not invent a publish or
   deploy command.
3. Keep the command, intended version, expected artifact, clean-environment
   smoke check, content exclusions, and rollback procedure in the active
   OpenSpec change's verification and release records.

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

## Release Gate

When all package evidence is complete, present a concise release-ready summary
and stop for an explicit user approval record. The record must approve the
exact version, release notes, target or environment, known warnings, rollback
plan, and exact external action. A previous approval is invalid if any of
those values changes.

Never infer approval from a request to “release”, a passing build, a prior
conversation, or a prepared `release.md`. Never perform an external release
action while approval is missing, ambiguous, or scoped to different values.

After an approved external command succeeds, record its command, exit code,
result identifier or URL when available, and post-release smoke result. Run
normal OpenSpec strict validation and archive only after that successful
release record. Do not bypass archive validation. If the external action or
post-release check fails, report `BLOCKED`, preserve the active change, and use
the recorded rollback plan; do not archive it.
