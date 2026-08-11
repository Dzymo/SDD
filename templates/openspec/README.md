# OpenSpec Authoring Guidance

These agent-maintained reference templates support the default OpenSpec
`spec-driven` artifact graph. The user supplies decisions in the session and
must not be asked to edit these files manually. They do not define a custom
schema. For every active change, run
`openspec instructions <artifact> --change <name> --json` first and use its
returned template and resolved path as the source of truth.

## Minimal Path

For a localized, low-risk change, use the default required graph: a concise
`proposal.md`, one or more delta specs, `design.md`, and `tasks.md`. Keep the
design short when the approach is obvious. Record focused verification before
archive.

## Larger Changes

Use `research.md` when a dependency, framework, external service, source
behavior, or unresolved claim needs evidence. Add `design.md` for cross-cutting
work, new dependencies, data changes, migrations, security, performance, or
meaningful architectural alternatives. Add `release.md` for any package,
deployment, publishing, or external write.

## Evidence And Change Rules

- Record source provenance and Context7 evidence in `research.md` whenever an
  external library, SDK, API, CLI, or service affects the change.
- Turn each normative requirement scenario into a candidate test or direct
  verification check. For a bug, security, data, public-API, or regression risk,
  add or update the focused check before implementation when practical. If a
  test is not proportionate, record the direct evidence and limitation.
- Pause for user approval before adding an unapproved runtime dependency or
  service; changing an API, schema, migration, auth, privacy, security, UI
  direction, release target, rollback plan, cost, scope, or delivery time; or
  taking a destructive or irreversible action.
- Routine inspection, focused tests, local refactors, and repairs inside the
  approved plan are not material deviations.

The agent creates `verification.md` and `release.md` under the `changeRoot`
returned by `openspec status`. Use verification evidence before claiming
completion. Release approval is explicit; after a successful release, validate
strictly and archive through OpenSpec.

A Session Goal may prepare package and release evidence only to
`ready for release`. Publish, deploy, tag, push, merge, production mutation, and
archive remain outside the Goal boundary and require the normal approval and
post-release gates.
