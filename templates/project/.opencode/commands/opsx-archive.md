---
description: Archive a completed, released OpenSpec change
---

Archive a completed OpenSpec change only after its release evidence is complete.

**Store selection:** If the user names a store or the work belongs to a registered standalone OpenSpec store, run `openspec store list --json` and pass `--store <id>` to commands that read or write changes and specs. Otherwise, use the nearest local `openspec/` root.

**Input:** Optionally specify a change name, for example `/opsx-archive add-auth`. If it is omitted or ambiguous, run `openspec list --json` and use AskUserQuestion to select an active change. Never guess or auto-select.

**Steps**

1. Run `openspec status --change "<name>" --json` and use its `schemaName`, `planningHome`, `changeRoot`, `artifactPaths`, and `artifacts` fields as the source of truth.
2. If any artifact is not `done`, display the incomplete artifacts and abort. Complete them through the schema-specific `openspec instructions <artifact-id> --change "<name>" --json` flow, then rerun status. User confirmation cannot override this gate.
3. Resolve the tasks artifact from status. If it exists and contains any `- [ ]` task, display the count and abort. Complete the tasks and their focused validation first. If no task artifact exists, confirm from status that the schema does not require one; otherwise abort and create it.
4. Assess delta specs from `artifactPaths.specs.existingOutputPaths`. If sync is needed, show the combined delta summary and offer `Sync now`, `Archive without syncing`, or `Cancel`. Syncing remains the recommended choice, but it cannot bypass any completion, release, or verification gate.
5. **Enforce framework release and approval gates before archive.** Resolve `release.md` and `verification.md` using `artifactPaths`; do not assume default filenames.

   **Release gate:** `release.md` must record the exact intended version, release notes, target, known warnings, rollback plan, external action, and explicit user approval for those exact values. It must also record the external action result and post-release smoke, both with exit code `0`. If the record is absent, incomplete, unapproved, stale for the recorded action, or failed, abort.

   **Pre-release validation gate:** Run `openspec validate <name> --strict --no-interactive` after the recorded external action. Record its exit code in `verification.md` or `release.md`. If it fails, is missing, or predates the external action, abort.

   **Verification gate:** `verification.md` must record requirement coverage for every requirement introduced by the change. Uncovered requirements must be addressed before archive. If coverage cannot be demonstrated, abort.

   **OpenSpec archive is forbidden without a successful recorded release.** A missing, incomplete, unapproved, or failed release is a release-not-yet-attempted condition, never a waiver.

6. Run the portable installed-CLI archive command from the project root:

   ```powershell
   openspec archive <change-name>
   ```

   The reviewed `@fission-ai/openspec@1.5.0` CLI manages archive naming and target existence. Do not create archive directories or move the change directory manually.
7. Report the change name, schema, archive location, spec-sync decision, recorded approval, post-release smoke result, strict-validation result, and requirement-coverage result.

**Archive Abort Conditions**

- Any artifact or task is incomplete.
- Release evidence or explicit approval is absent or does not match the action.
- The external action or post-release smoke failed.
- Strict validation did not pass after the external action.
- Requirement coverage is absent or incomplete.

**Guardrails**

- Never archive a change with incomplete artifacts or tasks.
- Never archive without a successful recorded release and its explicit user approval.
- Never archive after failing, skipped, or stale strict pre-release validation.
- Use only `openspec archive <change-name>` on Windows.
- Preserve `.openspec.yaml`; the OpenSpec CLI moves the complete change directory.
