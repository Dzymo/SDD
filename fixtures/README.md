# Fixtures

This directory is reserved for small, non-secret, deterministic inputs used by
framework verification. Phase 2 has no fixture that needs to exercise a global
configuration write.

`phase-6/ci-windows-only/` contains invalid and valid workflow inputs for the
Windows-only CI runner guard. The regression suite requires each invalid fixture
to produce its named failure and each valid fixture to produce no failures,
without executing a workflow.
