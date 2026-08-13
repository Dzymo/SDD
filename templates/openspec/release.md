# Release

This file is required only for a release-applicable change. A genuine
no-external-release change records `releaseApplicable: false` and its reason in
`verification.md`; it must not create fake approval or release-result evidence.

## Explicit User Approval

- Approved version:
- Approved release type / prerelease Boolean:
- Approved release notes:
- Approved target/environment:
- Approved known warnings:
- Approved rollback plan:
- Exact external action approved:
- Approval record (person, date, and exact text):

> Do not run an external action until every approval field is filled explicitly.
> Any changed version, notes, target, warning, rollback plan, or action needs a
> new approval record.

## Package Evidence

| Gate | Command or evidence | Result |
|---|---|---|
| Build/package | | |
| Clean install/run | | |
| Version | | |
| Secret/development-file scan | | |
| SHA-256 | | |
| Smoke test | | |

## Release Result

- Exact external action and command:
- Exit code:
- Result identifier or URL:
- Post-release smoke command and result:

## OpenSpec Archive

- Strict validation command and result:
- Archive command and result:

<!-- Record the external write result, then strictly validate and archive only
after it succeeds. Do not archive a failed, cancelled, or unapproved release. -->
