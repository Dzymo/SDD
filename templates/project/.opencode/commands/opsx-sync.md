---
description: Tự đồng bộ delta specs vào specification chính và tư vấn bước tiếp theo
---

Đồng bộ change được nêu sau command: `$ARGUMENTS`.

## Hợp Đồng Session

Contract markers: `SESSION-FIRST`, `USER-NO-FILE-EDIT`, `ADAPTIVE-INTERVIEW`,
`DECISION-READY-STOP`, `SYNC-EXACTLY-ONCE`, `NEXT-ACTION`,
`OPENCHAMBER-ADVICE`.

- Never ask the user to create or edit project files. Agent tự đọc và cập nhật
  specification; người dùng chỉ giải quyết điểm mơ hồ material.
- Khi delta có nhiều cách diễn giải, phỏng vấn theo chủ đề và trình bày một nhóm
  phương án dễ so sánh. Khuyến nghị một hướng; cho phép xem thêm nếu còn cách
  hiểu quan trọng trước khi ghi.
- Cuối mỗi phản hồi quan trọng luôn có `Bước tiếp theo:` và
  `Cách làm phù hợp:`.

## Cách Thực Hiện

1. Xác định local root hoặc store trước khi chọn change và giữ nguyên lựa chọn:
   - Local: nếu input trống hoặc mơ hồ, chạy `openspec list --json`; mọi lệnh
     lifecycle phải bỏ `--store`.
   - Store: chạy `openspec store list --json` để chọn ID, rồi nếu input trống
     hoặc mơ hồ chạy `openspec list --store <id> --json`; mọi lệnh lifecycle
     phải ghi rõ cùng một `--store <id>`.
   Yêu cầu người dùng chọn change khi còn mơ hồ; không đoán.
2. Chạy đúng một trong hai lệnh status và không trộn artifact store với
   `openspec/` cục bộ:

   ```bash
   # Local
   openspec status --change "<name>" --json

   # Store
   openspec status --change "<name>" --store <id> --json
   ```
3. Lấy delta spec từ `artifactPaths.specs.existingOutputPaths`. Nếu không có,
   thông báo và dừng.
4. Với từng capability, đọc delta và resolve main-spec destination từ root thực
   tế của local project hoặc selected store. Chỉ dùng
   `openspec/specs/<capability>/spec.md` khi change là local. Với store, dùng
   specification root do store metadata/CLI trả về; nếu không xác định được một
   writable destination có bằng chứng, dừng `BLOCKED` thay vì đoán hoặc ghi vào
   local `openspec/specs`.
5. Tự merge theo intent:
   - `ADDED`: thêm requirement khi chưa có. Nếu requirement tương đương đã tồn
     tại thì coi là đã sync và không ghi lại; nếu nội dung xung đột thì dừng để
     reconcile, không tạo bản trùng.
   - `MODIFIED`: chỉ thay phần được nêu, giữ nội dung không liên quan.
   - `REMOVED`: xóa toàn bộ requirement được chỉ định.
   - `RENAMED`: đổi tên requirement từ `FROM` sang `TO`.
6. Nếu main spec chưa tồn tại, tự tạo Purpose ngắn và Requirements từ phần
   `ADDED`. Đây là lần cập nhật spec duy nhất: command này tự merge delta, không
   gọi `openspec archive` để cập nhật spec và không áp dụng lại requirement đã
   hiện diện. Nếu chạy lại, xác minh delta đã phản ánh đầy đủ rồi không ghi lần
   hai. Ghi các path main spec đã đồng bộ vào `verification.md` để archive có
   evidence, nhưng archive vẫn phải đối chiếu nội dung thực tế.
7. Chạy strict validation bằng đúng một trong hai lệnh và tóm tắt requirement đã
   thêm, sửa, xóa hoặc đổi tên:

   ```bash
   # Local
   openspec validate <name> --strict --no-interactive

   # Store
   openspec validate <name> --store <id> --strict --no-interactive
   ```

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
