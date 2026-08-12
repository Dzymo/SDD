---
description: Rà soát evidence và archive change theo nhánh release-applicable hoặc no-release có guard, không vượt gate bằng confirmation
---

Archive change được nêu sau command: `$ARGUMENTS`.

## Hợp Đồng Session

Contract markers: `SESSION-FIRST`, `USER-NO-FILE-EDIT`, `NEXT-ACTION`,
`GOAL-SAFETY`, `OPENCHAMBER-ADVICE`, `RELEASE-GATE-BRANCH`,
`NO-RELEASE-GUARD`.

- Never ask the user to create or edit project files. Agent tự tạo/cập nhật
  `verification.md` và `release.md` từ câu trả lời, approval và command output.
- Người dùng chỉ cần cung cấp lựa chọn hoặc explicit approval trong session.
- Goal không được thực hiện publish, deploy, tag, push, merge, production
  mutation hoặc archive. Command này chỉ chạy external action sau explicit
  approval trong normal session và archive sau khi release cùng post-release
  smoke thành công.
- Two archive branches are enforced by source guard. Release applicability is
  decided from real evidence of package/deploy/publish/tag/push/merge/external
  write. A genuine no-external-release change must complete every other gate
  and record `releaseApplicable: false` with reason; it can never bypass task,
  artifact, validation, requirement, or strict-validation gates, and it must
  not invent a fake release approval/result.
- Cuối mỗi phản hồi quan trọng luôn có `Bước tiếp theo:` và
  `Cách làm phù hợp:`.

## Cách Thực Hiện

1. Xác định local root hoặc store trước khi chọn change và giữ nguyên lựa chọn:
   - Local: nếu input trống hoặc mơ hồ, chạy `openspec list --json`; mọi lệnh
     lifecycle phải bỏ `--store`.
   - Store: chạy `openspec store list --json` để chọn ID, rồi nếu input trống
     hoặc mơ hồ chạy `openspec list --store <id> --json`; mọi lệnh lifecycle
     phải ghi rõ cùng một `--store <id>`.
   Hỏi người dùng chọn change khi còn mơ hồ; không đoán.
2. Chạy đúng một trong hai lệnh status:

   ```bash
   # Local
   openspec status --change "<name>" --json

   # Store
   openspec status --change "<name>" --store <id> --json
   ```

   Dùng `changeRoot` làm gốc
   cho hai evidence file mở rộng của SDD:
   `<changeRoot>/verification.md` và `<changeRoot>/release.md`.
3. Resolve tasks artifact từ status, rồi chạy
   `openspec instructions <tasks-artifact-id> --change "<name>" --json` cho local
   hoặc `openspec instructions <tasks-artifact-id> --change "<name>" --store <id>
   --json` cho store và đọc file thực tế. Nếu còn
   bất kỳ checkbox `- [ ]`, artifact bắt buộc chưa hoàn tất, implementation chưa
   xong hoặc focused validation chưa có exit code `0`, dừng archive và trả về
   `/opsx-apply <name>`. Không tự thực hiện task, đánh dấu task hoàn tất, suy diễn
   completion evidence hoặc cho phép confirmation bỏ qua gate. Chỉ được bổ sung
   `verification.md` và `release.md` từ command output/approval đã thực sự tồn tại.
4. Đối chiếu từng `ADDED`, `MODIFIED`, `REMOVED`, `RENAMED` với main specs trong
   đúng root đã chọn và phân loại trước archive:
   - **Đã sync đầy đủ:** `/opsx-sync` đã tự merge delta một lần; archive phải
     dùng `--skip-specs --yes` để không áp dụng lần hai.
   - **Chưa sync:** không merge thủ công trong command này; archive phải dùng
     `--yes` và để OpenSpec cập nhật main specs đúng một lần.
   - **Partial hoặc không chứng minh được:** dừng `BLOCKED`; không đoán và không
     archive. Có thể chạy `/opsx-sync <name>` để hoàn tất manual merge, sau đó
     quay lại nhánh đã sync.
   Không bao giờ chạy manual sync rồi archive thiếu `--skip-specs`.
5. **Decide the archive branch from real change scope (`releaseApplicable`).**
   Quyết định nhánh archive từ evidence thực tế của change; không bao giờ hạ
   cấp từ release-applicable xuống no-release để tránh gate release:
   - **Release-applicable** bắt buộc khi bất kỳ điều nào sau đúng với change
     này: `PACKAGE.md` được tạo hoặc cập nhật bởi change; `proposal.md` hoặc
     `design.md` chỉ định package, deploy, publish, container/build artifact,
     tag, push, merge, release hoặc bất kỳ external write nào; planned action
     trong `tasks.md` chạm package/deploy/publish; hoặc `release.md` đã tồn
     tại với external action hoặc result đã ghi.
   - **No-external-release** chỉ hợp lệ khi không có release indicator nào ở
     trên. Không được diễn dịch "không thấy `PACKAGE.md`" thành no-release nếu
     change thực sự package/deploy/publish; phải đối chiếu cả `proposal.md`,
     `design.md`, `tasks.md` và `release.md` trước khi hạ nhánh.
   - Bất kỳ confirmation nào cũng không chọn được nhánh no-release khi release
     indicator tồn tại; đây là failure-closed quy tắc nguồn.
6. **Release-applicable branch: enforce framework release, approval, and
   post-release gates.**
   - `release.md` phải ghi đúng version, release notes, target, known warnings,
     rollback plan, exact external action và explicit approval cho đúng bộ giá trị.
   - Nếu thiếu dữ kiện, agent phỏng vấn và tự cập nhật file. Nếu external action
     chưa được phê duyệt hoặc chưa chạy thành công, dừng; không tự phát hành.
   - External action và post-release smoke phải có exit code `0`.
   - Approval chỉ áp dụng cho đúng bộ giá trị đã ghi; đổi bất kỳ value nào làm
     approval cũ vô hiệu và phải xin approval mới.
7. **No-external-release branch: enforce `NO-RELEASE-GUARD`.** Nhánh chỉ hợp
   lệ khi bước 5 xác nhận không có release indicator và mọi điều kiện dưới
   đều đã ghi bằng chứng thực tế trong `<changeRoot>/verification.md`:
   - Toàn bộ checkbox `- [ ]` trong tasks đã tick và mọi artifact apply bắt
     buộc đã có evidence (xác minh lại ở bước 3).
   - Requirement coverage map từng requirement sang test/evidence trực tiếp.
   - Fresh focused validation (lệnh, output, exit code `0`) đã chạy; không dùng
     evidence stale hoặc evidence của change khác.
   - Strict `openspec validate ... --strict --no-interactive` đã chạy với exit
     code `0` ngay trước khi vào nhánh này.
   - `verification.md` ghi rõ `releaseApplicable: false` và reason ngắn (change
     này không đụng package/deploy/publish/tag/push/merge/external write).
   Cấm tuyệt đối: dùng user confirmation để vượt bất kỳ gate nào ở trên, ghi
   giả `RELEASED-OK`, fake approval/result, tạo hoặc sửa evidence thiếu, hoặc
   hạ cấp một change thực sự release xuống nhánh này. Bất kỳ điều kiện nào
   chưa đạt đều dừng và trả về `/opsx-apply <change-name>`; không archive.
8. **Pre-release / pre-archive strict validation gate:** sau external action
   (nhánh release) hoặc sau fresh focused validation (nhánh no-release), chạy:

   ```bash
   # Local
   openspec validate <name> --strict --no-interactive

   # Store
   openspec validate <name> --store <id> --strict --no-interactive
   ```

   Tự ghi command, thời điểm và exit code vào evidence. Kết quả thiếu, stale
   hoặc thất bại đều chặn archive bất kể nhánh.
9. **Verification gate:** `verification.md` phải map mọi requirement của change
   sang test hoặc evidence và ghi remaining uncertainty. Agent tự bổ sung từ kết
   quả đã chạy; coverage không chứng minh được thì dừng. Nhánh no-release còn
   phải chứa `releaseApplicable: false` và reason ở đây (xem bước 7).
10. **OpenSpec archive is forbidden without a passing branch gate.** Không
    được archive failed, cancelled, incomplete change, và confirmation bỏ
    gate là cấm. Cả nhánh release-applicable và nhánh no-external-release đều
    dùng chung một trong bốn lệnh Phase 1 sau, dựa trên root và trạng thái
    sync đã chọn ở bước 1 và 4. Nhánh no-release không được thay cờ lệnh
    (`--yes` và `--skip-specs` vẫn bắt buộc như nhánh release) và không được
    bỏ bất kỳ gate nào ở trên:

   ```powershell
   # Local, delta da duoc /opsx-sync merge
   openspec archive <change-name> --skip-specs --yes

   # Local, delta chua sync; OpenSpec cap nhat spec mot lan
   openspec archive <change-name> --yes

   # Store, delta da duoc /opsx-sync merge
   openspec archive <change-name> --store <id> --skip-specs --yes

   # Store, delta chua sync; OpenSpec cap nhat spec mot lan
   openspec archive <change-name> --store <id> --yes
   ```

   Không chạy `openspec archive <change-name>` thiếu `--yes`, không tạo hoặc di
   chuyển archive directory thủ công và giữ nguyên `.openspec.yaml` để CLI quản
   lý.

## Kết Thúc

Tóm tắt archive location, quyết định sync, archive branch (release-applicable
hay no-external-release kèm `releaseApplicable` value và reason), approval (chỉ
khi release-applicable), release result (chỉ khi release-applicable), post-release
smoke (chỉ khi release-applicable), strict validation và requirement coverage.

```text
Bước tiếp theo: /opsx-explore <ý tưởng tiếp theo> hoặc /opsx-propose <change tiếp theo>
Cách làm phù hợp: Không dùng Goal hoặc worktree chỉ để kết thúc một archive đã hoàn tất.
```
