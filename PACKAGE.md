# Package Contract

## Delivery

- Intended version: `v0.1.0-rc.1`
- Package/build command:
  `PowerShell -NoProfile -ExecutionPolicy Bypass -File .\scripts\New-ReleaseCandidatePackage.ps1 -Version v0.1.0-rc.1 -OutputDirectory <path>`
- Expected artifact: `sdd-v0.1.0-rc.1-source.zip`
- Version inspection: read `RELEASE-MANIFEST.json` from the ZIP and require
  `version = v0.1.0-rc.1` and
  `targetSha = a431be0064dc5b84abc31bb60fcbb94eaa185661`.

## Clean Environment Smoke

- Create a new temporary directory and extract the packaged source there.
- Run `scripts\Test-FrameworkSkeleton.ps1`,
  `scripts\Test-CiWindowsOnlyRegression.ps1`, and
  `scripts\Test-PackagingRelease.ps1` from the extracted artifact.
- Every command must exit `0` without using the source workspace.

## Delivered Content Checks

- Exclude `.git`, `.slim`, `node_modules`, runtime backups, environment files,
  private keys, certificates, and package-manager logs.
- Run the framework source safety gate from the extracted artifact.
- Record SHA-256 in `sdd-v0.1.0-rc.1-source.zip.sha256` and publish the external
  `sdd-v0.1.0-rc.1-release-manifest.json` beside the ZIP.

## Release And Rollback

- Exact external action: create tag `v0.1.0-rc.1` at
  `a431be0064dc5b84abc31bb60fcbb94eaa185661` and publish a GitHub prerelease in
  `Dzymo/SDD` with the source ZIP, checksum, and release manifest.
- Target/environment: GitHub Releases for `Dzymo/SDD`.
- Post-release smoke: download all published assets, verify checksum and both
  manifests, extract the ZIP into a new temporary directory, and rerun the
  three clean-environment smoke gates.
- Rollback: delete GitHub release `v0.1.0-rc.1` and its tag. No deployment,
  registry publication, or active-global configuration write is performed.
- Archive/release is blocked by a mismatched target SHA, existing release/tag,
  failed package gate, failed asset upload, failed checksum/manifest check, or
  failed post-release smoke.
