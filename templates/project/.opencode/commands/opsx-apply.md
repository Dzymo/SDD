---
description: Tự hoàn thiện artifact, triển khai tasks và ghi bằng chứng kiểm chứng
---

Triển khai change được nêu sau command: `$ARGUMENTS`.

## Hợp Đồng Session

Contract markers: `SESSION-FIRST`, `USER-NO-FILE-EDIT`, `ADAPTIVE-INTERVIEW`,
`DECISION-READY-STOP`, `GOAL-SAFETY`, `NEXT-ACTION`,
`OPENCHAMBER-ADVICE`.

- Never ask the user to create or edit project files. Agent tự cập nhật artifact,
  mã nguồn, task checkbox và bằng chứng; người dùng chỉ quyết định material
  deviation hoặc phê duyệt hành động bên ngoài.
- Khi có lựa chọn kỹ thuật quan trọng, phỏng vấn theo chủ đề, trình bày một nhóm
  phương án dễ so sánh và khuyến nghị một hướng. Cho phép người dùng giao AI
  chọn mặc định kỹ thuật có thể đảo ngược và rủi ro thấp.
- Cuối mỗi phản hồi quan trọng luôn có `Bước tiếp theo:` và
  `Cách làm phù hợp:`.

## Cách Thực Hiện

1. Chọn change từ input hoặc ngữ cảnh. Nếu mơ hồ, chạy `openspec list --json`
   và hỏi người dùng chọn; luôn thông báo change đang dùng.
2. Xác định local root hoặc store, rồi chạy:

   ```bash
   openspec status --change "<name>" --json
   openspec instructions apply --change "<name>" --json
   ```

3. Nếu apply trả về `blocked`, profile core provides no built-in continuation surface.
   Agent tự phục hồi, không giao người dùng sửa file:
   - Đọc từng artifact `not_done` từ status.
   - Chạy `openspec instructions <artifact-id> --change "<name>" --json`.
   - Đọc mọi `contextFiles`, tự ghi đúng `resolvedOutputPath`, rồi chạy lại status.
   - Lặp đến khi apply là `ready` hoặc `in_progress`.
   - Chỉ phỏng vấn người dùng khi thiếu một quyết định material.
4. Đọc mọi file trong `contextFiles` của apply instructions. Tôn trọng
   `actionContext`, allowed edit roots, proposal, specs, design và tasks.
5. Trước implementation nhiều bước, đưa `Cách làm phù hợp:`. Công việc ghi code
   chỉ được đề xuất Worktree + Goal khi scope, quyết định, completion evidence,
   blocked conditions và writer ownership đã rõ. Goal đơn lẻ chỉ dùng cho
   read-only/deterministic work hoặc session đã ở trong worktree; không tự bật,
   resume hoặc tăng budget.
6. Thực hiện từng task pending với thay đổi nhỏ nhất đúng yêu cầu. Chạy focused
   validation, rồi đổi `- [ ]` thành `- [x]` ngay khi task thực sự hoàn thành.
7. Nếu implementation làm lộ vấn đề trong spec/design, tự đề xuất phương án và
   cập nhật artifact sau quyết định của người dùng. Không yêu cầu họ sửa file.
8. Với bug hồi quy hoặc hành vi rủi ro, tạo focused regression check khi phù hợp.
   Sau hai lần sửa thất bại, dừng blind repair và đánh giá lại root cause.
9. Sau task cuối, chạy project-native checks và strict validation. Tạo hoặc cập
   nhật `<changeRoot>/verification.md` với command, exit code, requirement
   coverage và remaining uncertainty.

## Kết Thúc

- Nếu còn delta spec chưa đồng bộ:

  ```text
  Bước tiếp theo: /opsx-sync <change-name>
  Cách làm phù hợp: Không dùng Goal nếu chỉ còn đồng bộ và rà soát ngắn.
  ```

- Nếu cần package/release, Goal có thể build/package, kiểm tra artifact, chạy
  clean smoke, tính checksum, chuẩn bị release notes, cảnh báo và rollback đến
  `ready for release`. Goal phải dừng trước publish, deploy, tag, push, merge,
  production mutation hoặc archive. Tiếp tục trong session để agent xin explicit
  approval và tự cập nhật `PACKAGE.md`, `verification.md`, `release.md`.
- Chỉ đề xuất `/opsx-archive <change-name>` sau khi mọi release, approval,
  post-release smoke và strict validation bắt buộc đã hoàn tất.
