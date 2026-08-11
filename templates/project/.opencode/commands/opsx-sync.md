---
description: Tự đồng bộ delta specs vào specification chính và tư vấn bước tiếp theo
---

Đồng bộ change được nêu sau command: `$ARGUMENTS`.

## Hợp Đồng Session

Contract markers: `SESSION-FIRST`, `USER-NO-FILE-EDIT`, `ADAPTIVE-INTERVIEW`,
`DECISION-READY-STOP`, `NEXT-ACTION`, `OPENCHAMBER-ADVICE`.

- Never ask the user to create or edit project files. Agent tự đọc và cập nhật
  specification; người dùng chỉ giải quyết điểm mơ hồ material.
- Khi delta có nhiều cách diễn giải, phỏng vấn theo chủ đề và trình bày một nhóm
  phương án dễ so sánh. Khuyến nghị một hướng; cho phép xem thêm nếu còn cách
  hiểu quan trọng trước khi ghi.
- Cuối mỗi phản hồi quan trọng luôn có `Bước tiếp theo:` và
  `Cách làm phù hợp:`.

## Cách Thực Hiện

1. Nếu input trống hoặc mơ hồ, chạy `openspec list --json` và yêu cầu người dùng
   chọn change; không đoán.
2. Xác định local root hoặc store. Nếu dùng store, giữ `--store <id>` trong mọi
   lệnh status, instructions, validation và sync; không trộn artifact store với
   `openspec/` cục bộ. Chạy `openspec status --change "<name>" --json` cùng
   store argument đã chọn.
3. Lấy delta spec từ `artifactPaths.specs.existingOutputPaths`. Nếu không có,
   thông báo và dừng.
4. Với từng capability, đọc delta và resolve main-spec destination từ root thực
   tế của local project hoặc selected store. Chỉ dùng
   `openspec/specs/<capability>/spec.md` khi change là local. Với store, dùng
   specification root do store metadata/CLI trả về; nếu không xác định được một
   writable destination có bằng chứng, dừng `BLOCKED` thay vì đoán hoặc ghi vào
   local `openspec/specs`.
5. Tự merge theo intent:
   - `ADDED`: thêm requirement mới; nếu đã tồn tại thì cập nhật có chủ đích.
   - `MODIFIED`: chỉ thay phần được nêu, giữ nội dung không liên quan.
   - `REMOVED`: xóa toàn bộ requirement được chỉ định.
   - `RENAMED`: đổi tên requirement từ `FROM` sang `TO`.
6. Nếu main spec chưa tồn tại, tự tạo Purpose ngắn và Requirements từ phần
   `ADDED`. Đảm bảo chạy lặp lại không tạo nội dung trùng.
7. Chạy strict validation và tóm tắt requirement đã thêm, sửa, xóa hoặc đổi tên.

## Kết Thúc

- Nếu implementation hoặc verification còn thiếu:

  ```text
  Bước tiếp theo: /opsx-apply <change-name>
  Cách làm phù hợp: Worktree + Goal chỉ khi còn một khối ghi code nhiều bước có finish line rõ.
  ```

- Nếu release evidence đã hoàn tất:

  ```text
  Bước tiếp theo: /opsx-archive <change-name>
  Cách làm phù hợp: Không dùng Goal cho bước archive ngắn; dừng nếu còn external action chưa được phê duyệt.
  ```
