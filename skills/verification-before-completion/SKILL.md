---
name: verification-before-completion
description: Verify a code change before reporting it complete, fixed, or passing. Use immediately before a PASS claim, task completion, commit, pull request, package, or release record.
---

# Verification Before Completion

1. Map every acceptance criterion to one focused command or direct observable check.
2. Run the required command after the final relevant change.
3. Inspect the command output and exit code, not only an agent report or a prior run.
4. Record each command, exit code, result, and any limitation.
5. Report `PASS` only when every required check passed and directly supports the claimed outcome.

A failed command, an unrun required command, a skipped check without a stated limitation, or a regression that was not retested must produce `BLOCKED` or `ESCALATE`, never `PASS`.
