---
description: Phỏng vấn và tự tạo change cùng toàn bộ artifact cần để triển khai
---

Tạo proposal từ nội dung người dùng nhập sau command: `$ARGUMENTS`.

## Hợp Đồng Session

Contract markers: `SESSION-FIRST`, `USER-NO-FILE-EDIT`, `ADAPTIVE-INTERVIEW`,
`DECISION-READY-STOP`, `NEXT-ACTION`, `OPENCHAMBER-ADVICE`.

- Người dùng chỉ trả lời, chọn phương án và phê duyệt trong session. Never ask
  the user to create or edit project files; agent tự duy trì `PRODUCT.md`,
  `DESIGN.md`, surface brief và toàn bộ OpenSpec artifact.
- Phỏng vấn theo chủ đề, không giới hạn cứng số câu, số lượt hoặc số phương án.
  Chỉ mở rộng khi câu trả lời có thể thay đổi kế hoạch; sau mỗi vòng, tóm tắt
  điều đã hiểu, điểm còn mở và khuyến nghị.
- Cuối mỗi phản hồi quan trọng luôn có `Bước tiếp theo:` và
  `Cách làm phù hợp:`.

## Cách Thực Hiện

1. Nếu input trống, hỏi người dùng muốn xây dựng hoặc sửa điều gì. Từ mô tả đã
   hiểu, đề xuất tên kebab-case và xác nhận nếu tên có thể gây hiểu nhầm.
2. Xác định local OpenSpec root hoặc store và giữ nguyên lựa chọn đó. Local dùng
   `openspec list --json` và mọi lệnh lifecycle bên dưới phải bỏ `--store`.
   Với store, chạy `openspec store list --json`, chọn ID, rồi chạy
   `openspec list --store <id> --json`; mọi lệnh lifecycle bên dưới phải ghi rõ
   cùng một `--store <id>`.
3. Đọc `PRODUCT.md`. Nếu thiếu, chỉ có comment template hoặc thiếu product fact
   cần cho change, phỏng vấn người dùng rồi tự tạo/cập nhật file. Không yêu cầu
   người dùng mở hoặc điền file.
4. Nếu change có UI mới hoặc redesign đáng kể mà hướng thiết kế chưa được duyệt,
   đưa một nhóm nhỏ hướng khác biệt để dễ so sánh, khuyến nghị một hướng và cho
   phép xem thêm khi còn lựa chọn quan trọng. Sau lựa chọn, tự cập nhật
   `DESIGN.md` và surface brief liên quan.
5. Nếu change chưa tồn tại, chạy đúng một trong hai lệnh:

   ```bash
   # Local
   openspec new change "<name>" --json

   # Store
   openspec new change "<name>" --store <id> --json
   ```

   Nếu đã tồn tại, hỏi tiếp tục change đó hay tạo tên khác.
6. Chạy đúng một trong hai lệnh status:

   ```bash
   # Local
   openspec status --change "<name>" --json

   # Store
   openspec status --change "<name>" --store <id> --json
   ```

   Dùng `planningHome`, `changeRoot`, `artifactPaths`, `actionContext`,
   `applyRequires` và danh sách `artifacts` làm nguồn sự thật; không đoán path.
7. Theo thứ tự dependency, với mỗi artifact `ready`, chạy:

   ```bash
   # Local
   openspec instructions <artifact-id> --change "<name>" --json

   # Store
   openspec instructions <artifact-id> --change "<name>" --store <id> --json
   ```

   Đọc dependency/context files, áp dụng `context`, `rules`, `template` và
   `instruction`, rồi tự ghi vào `resolvedOutputPath`. Với API/dependency bên
   ngoài, lấy evidence theo phiên bản và đưa quyết định vào artifact phù hợp.
8. Sau mỗi artifact, chạy lại đúng lệnh status local hoặc store ở bước 6. Tiếp
   tục đến khi mọi `applyRequires` đều `done`. Nếu thiếu một quyết định quan
   trọng, tiếp tục phỏng vấn theo chủ đề đến khi mục tiêu, phạm vi, ràng buộc và
   cách kiểm chứng đủ rõ; không giao việc sửa file cho người dùng.
9. Chạy strict validation và tự sửa lỗi artifact trong phạm vi đã thống nhất:

   ```bash
   # Local
   openspec validate <name> --strict --no-interactive

   # Store
   openspec validate <name> --store <id> --strict --no-interactive
   ```

## Kết Thúc

Tóm tắt change, artifact đã tạo, quyết định của người dùng, rủi ro và lệnh kiểm
chứng dự kiến. Nếu change đã apply-ready:

```text
Bước tiếp theo: /opsx-apply <change-name>
Cách làm phù hợp: Worktree + Goal nếu đây là triển khai ghi code nhiều bước có tiêu chí hoàn thành rõ; nếu thay đổi nhỏ thì dùng chat thường.
```

Khi đề xuất Goal, cung cấp objective gồm outcome, scope, completion evidence,
constraints và blocked conditions; agent không tự bật Goal hoặc tạo worktree.
