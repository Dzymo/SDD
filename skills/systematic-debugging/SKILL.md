---
name: systematic-debugging
description: Debug a bug, test failure, build failure, or unexpected behavior after the fast path fails. Use before a repair when the cause is not already demonstrated, and stop blind edits after two failed repairs.
---

# Systematic Debugging

Use this only for a failure or unexpected behavior, not routine implementation.

1. Capture the exact failing command, exit code, error, reproduction input, and affected path.
2. Identify one likely cause from direct local evidence. Compare a nearby working path when useful.
3. State one testable hypothesis and make the smallest change that can test it.
4. Run the focused reproduction or regression check and inspect its complete result.
5. After the first failed repair, repeat from the observed evidence, not the prior guess.
6. After the second failed repair, stop editing. Return the commands, outputs, changes, and invalid assumption for Oracle or the Orchestrator to review.

For a regression bug, add or update a focused regression check before the fix when practical. If a repeatable check is not practical, explain why and name the direct evidence used instead.
