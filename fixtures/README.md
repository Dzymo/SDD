# Fixtures

This directory is reserved for small, non-secret, deterministic inputs used by
framework verification. Phase 2 has no fixture that needs to exercise a global
configuration write.

`phase-6/ci-windows-only/` contains invalid and valid workflow inputs for the
Windows-only CI runner guard. The regression suite requires each invalid fixture
to produce its named failure and each valid fixture to produce no failures,
without executing a workflow.

`phase-7/` contains deterministic execution records for a passing feature, a
bug with regression evidence, two failed repairs requiring Oracle assumption
review, and a deliberately false PASS record. The Phase 7 gate must reject the
false PASS without running an application command.

`phase-8/` contains deterministic advisory scenarios for normal chat, Focus
Mode, Session Goals, worktrees, isolated MultiRun, and release approval. The
Phase 8 gate must reject Goal and MultiRun recommendations with missing safety
preconditions.

`phase-9/` contains deterministic UI evidence scenarios. The Phase 9 gate
requires product/design/surface authority, desktop/mobile/browser/accessibility
evidence, and a separate screenshot review; it distinguishes review-ready from
explicit user visual approval and rejects synthetic-score proof.

`phase-10/` contains release-decision scenarios and a dependency-free local
package. The Phase 10 gate packs it in a temporary directory, installs it in a
separate clean directory, and removes those temporary outputs after the check;
it never contacts a registry or makes an external release action.

`phase-11/` contains the 18 deterministic evaluation and failure-drill records
from the implementation plan. Its gate derives each safe verdict, checks the
cross-phase source contracts, and does not call a provider, change global
configuration, create a worktree, or make an external release action.
