# Changelog

Nhật ký này tóm tắt thay đổi có ảnh hưởng đến người dùng và người vận hành.
Phase record, release plan và Git history vẫn là bằng chứng chi tiết.

## Unreleased

### Added

- Deterministic read-only global apply readiness preflight với verdict
  `NO_APPLY_REQUIRED`, `READY_FOR_GLOBAL_APPLY`, và `BLOCKED`.
- Regression coverage cho target drift, target vắng mặt, candidate bẩn, process
  đang chạy, Phase 5 package identity và output sanitization.
- Hướng dẫn phân biệt source/CI, isolated managed runtime, active target/hash,
  và provider/manual behavior evidence.

### Changed

- Tài liệu vận hành được đồng bộ với public source hosting, stable `v0.1.0`,
  release automation và global-readiness evidence mới nhất.
- Archive contract hỗ trợ local/store và synced/unsynced, đồng thời phân biệt
  release-applicable với genuine no-external-release qua `releaseApplicable`.
- Structured media handoff được mô tả theo phạm vi đã kiểm chứng: PNG, JPEG,
  GIF và WebP; video handoff chưa được công bố là verified.

### Version Boundary

- Development commit `e5bb0ed775a6c1340089a0f299c6699ac533bf20`
  chứa global-readiness preflight và đã qua CI run `31651664360`.
- Các tooling commit này mới hơn stable payload và không nằm trong ZIP
  `v0.1.0`.

## v0.1.0 - 2026-08-12

### Added

- Stable/RC release-plan contract với Boolean `prerelease` rõ ràng.
- Manual GitHub release workflow với asset verification và rollback release/tag
  được tạo bởi một run thất bại.
- OpenSpec local/store lifecycle, synced/unsynced archive và no-external-release
  archive branch.
- Session-first adaptive interview, Goal/worktree boundary, UI quality layer,
  package evidence và deterministic failure drills.

### Release

- Payload SHA: `a431be0064dc5b84abc31bb60fcbb94eaa185661`.
- Release URL: <https://github.com/Dzymo/SDD/releases/tag/v0.1.0>.
- Stable payload giữ nguyên source đã được chấp nhận từ `v0.1.0-rc.1`; các
  release-automation commit thêm sau đó không được đưa vào ZIP.
