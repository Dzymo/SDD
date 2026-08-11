---
description: Phỏng vấn, brainstorm và làm rõ sản phẩm hoặc thay đổi trước khi triển khai
---

Khám phá nội dung người dùng nhập sau command: `$ARGUMENTS`.

## Hợp Đồng Session

Contract markers: `SESSION-FIRST`, `USER-NO-FILE-EDIT`, `ADAPTIVE-INTERVIEW`,
`DECISION-READY-STOP`, `NEXT-ACTION`, `OPENCHAMBER-ADVICE`.

- Trao đổi bằng tiếng Việt trừ khi người dùng chọn ngôn ngữ khác.
- Người dùng chỉ cung cấp ý định, lựa chọn và phê duyệt trong session. Never ask
  the user to create or edit project files; agent tự đọc, tạo và cập nhật mọi
  artifact cần thiết.
- Phỏng vấn theo chủ đề liên quan, không giới hạn cứng số câu, số lượt hoặc số
  phương án. Một lượt có thể hỏi nhiều câu cùng chủ đề; không trộn các chủ đề
  không liên quan thành một biểu mẫu dài.
- Thông thường so sánh một nhóm nhỏ phương án dễ đọc. Nếu còn hướng quan trọng,
  nhóm chúng, khuyến nghị các hướng mạnh nhất và cho phép người dùng xem thêm.
- Không tự ghi suy đoán chưa được người dùng xác nhận thành product truth.
- Cuối mỗi phản hồi quan trọng luôn có `Bước tiếp theo:` và
  `Cách làm phù hợp:` kèm lý do ngắn.

## Cách Thực Hiện

1. Xác định scope OpenSpec. Mặc định dùng `openspec/` gần nhất. Nếu người dùng
   nêu store hoặc change thuộc store, chạy `openspec store list --json` và giữ
   `--store <id>` cho các lệnh tiếp theo.
2. Đọc `PRODUCT.md`, `DESIGN.md`, surface brief liên quan và
   `openspec list --json` nếu chúng tồn tại.
3. Nếu `PRODUCT.md` thiếu hoặc chỉ còn comment template, bắt đầu bằng thông tin
   định hướng tối thiểu rồi mở rộng theo câu trả lời. Chỉ hỏi thêm khi thông tin
   có thể thay đổi phạm vi, UI, dữ liệu, bảo mật, chi phí, release hoặc cách kiểm
   chứng. Sau mỗi vòng, tóm tắt điều đã hiểu và tự cập nhật các quyết định đã
   xác nhận vào `PRODUCT.md`.
4. Khảo sát mã nguồn khi câu hỏi liên quan hệ thống hiện có. Với dependency/API,
   lấy bằng chứng theo phiên bản trước khi khuyến nghị.
5. Brainstorm các hướng thực sự khác nhau theo nhóm dễ so sánh. Đánh giá giá trị
   sản phẩm, độ phức tạp, rủi ro, chi phí và khả năng kiểm chứng; khuyến nghị một
   hướng và cho phép xem thêm khi còn lựa chọn quan trọng.
6. Khi có quyết định bền vững, tự cập nhật `DESIGN.md`. Với UI mới hoặc redesign
   đáng kể, sau khi người dùng chọn hướng, tự tạo/cập nhật
   `docs/surfaces/<surface>.md`.
7. Nếu đang khám phá một change, lấy path thật bằng
   `openspec status --change "<name>" --json`, đọc artifact hiện có và tự cập
   nhật proposal/spec/design/tasks sau khi người dùng xác nhận thay đổi.

## Giới Hạn

- Không triển khai mã ứng dụng trong explore mode.
- Không ép người dùng trả lời toàn bộ bảng câu hỏi trong một lượt.
- Không kết thúc chỉ vì đã đạt một số câu hoặc số vòng; kết thúc khi mục tiêu,
  người dùng, phạm vi, ràng buộc, quyết định mở và cách kiểm chứng đã đủ rõ.
- Không bật Session Goal khi quyết định sản phẩm hoặc UI còn mở.
- Chỉ đề xuất MultiRun khi việc so sánh các phương án độc lập đủ giá trị và mỗi
  phương án có thể chạy trong worktree riêng.

Khi đã đủ rõ để formalize, đề xuất:

```text
Bước tiếp theo: /opsx-propose <change-name hoặc mô tả>
Cách làm phù hợp: Không dùng Goal; dùng Focus Mode nếu chủ đề tiếp theo cần câu trả lời dài hoặc có nhiều ràng buộc.
```
