---
description: Rà soát evidence, phê duyệt và archive một change đã phát hành thành công
---

Archive change được nêu sau command: `$ARGUMENTS`.

## Hợp Đồng Session

Contract markers: `SESSION-FIRST`, `USER-NO-FILE-EDIT`, `NEXT-ACTION`,
`GOAL-SAFETY`, `OPENCHAMBER-ADVICE`.

- Never ask the user to create or edit project files. Agent tự tạo/cập nhật
  `verification.md` và `release.md` từ câu trả lời, approval và command output.
- Người dùng chỉ cần cung cấp lựa chọn hoặc explicit approval trong session.
- Goal không được thực hiện publish, deploy, tag, push, merge, production
  mutation hoặc archive. Command này chỉ chạy external action sau explicit
  approval trong normal session và archive sau khi release cùng post-release
  smoke thành công.
- Cuối mỗi phản hồi quan trọng luôn có `Bước tiếp theo:` và
  `Cách làm phù hợp:`.

## Cách Thực Hiện

1. Nếu input trống hoặc mơ hồ, chạy `openspec list --json` và hỏi người dùng
   chọn change; không đoán. Xác định local root hoặc store.
2. Chạy `openspec status --change "<name>" --json`. Dùng `changeRoot` làm gốc
   cho hai evidence file mở rộng của SDD:
   `<changeRoot>/verification.md` và `<changeRoot>/release.md`.
3. Resolve tasks artifact từ status/instructions và đọc file thực tế. Nếu còn
   bất kỳ checkbox `- [ ]`, artifact bắt buộc chưa hoàn tất, implementation chưa
   xong hoặc focused validation chưa có exit code `0`, dừng archive và trả về
   `/opsx-apply <name>`. Không tự thực hiện task, đánh dấu task hoàn tất, suy diễn
   completion evidence hoặc cho phép confirmation bỏ qua gate. Chỉ được bổ sung
   `verification.md` và `release.md` từ command output/approval đã thực sự tồn tại.
4. Đánh giá delta specs. Nếu cần sync, khuyến nghị `/opsx-sync <name>`; chỉ
   archive không sync khi người dùng chọn rõ và các gate khác vẫn đạt.
5. **Enforce framework release and approval gates before archive.**
   - `release.md` phải ghi đúng version, release notes, target, known warnings,
     rollback plan, exact external action và explicit approval cho đúng bộ giá trị.
   - Nếu thiếu dữ kiện, agent phỏng vấn và tự cập nhật file. Nếu external action
     chưa được phê duyệt hoặc chưa chạy thành công, dừng; không tự phát hành.
   - External action và post-release smoke phải có exit code `0`.
6. **Pre-release validation gate:** sau external action, chạy:

   ```bash
   openspec validate <name> --strict --no-interactive
   ```

   Tự ghi command, thời điểm và exit code vào evidence. Kết quả thiếu, stale
   hoặc thất bại đều chặn archive.
7. **Verification gate:** `verification.md` phải map mọi requirement của change
   sang test hoặc evidence và ghi remaining uncertainty. Agent tự bổ sung từ kết
   quả đã chạy; coverage không chứng minh được thì dừng.
8. **OpenSpec archive is forbidden without a successful recorded release.**
   Khi mọi gate đạt, chạy lệnh portable từ project root:

   ```powershell
   openspec archive <change-name>
   ```

   Giữ `--store <id>` khi change thuộc store. Không tạo hoặc di chuyển archive
   directory thủ công; giữ nguyên `.openspec.yaml` để CLI quản lý.

## Kết Thúc

Tóm tắt archive location, quyết định sync, approval, release result,
post-release smoke, strict validation và requirement coverage.

```text
Bước tiếp theo: /opsx-explore <ý tưởng tiếp theo> hoặc /opsx-propose <change tiếp theo>
Cách làm phù hợp: Không dùng Goal hoặc worktree chỉ để kết thúc một archive đã hoàn tất.
```
