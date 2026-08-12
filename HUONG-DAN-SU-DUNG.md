# Hướng Dẫn Sử Dụng SDD

Tài liệu này hướng dẫn sử dụng SDD theo thứ tự phát triển một dự án. Phần mô tả
tính năng và công nghệ nằm trong [README.md](README.md); ở đây chỉ tập trung vào
điều kiện cần có, thao tác, lệnh và cổng quyết định.

Nguyên tắc sử dụng: bạn chỉ giao tiếp với agent trong session. Không tự mở hoặc
điền `PRODUCT.md`, `DESIGN.md`, `PACKAGE.md`, surface brief hay OpenSpec
artifact. Agent phải phỏng vấn, đưa phương án và khuyến nghị, sau đó tự tạo hoặc
cập nhật file từ quyết định đã xác nhận.

## 1. Điều Kiện Trước Khi Bắt Đầu

Chuẩn bị các điều kiện sau trên máy Windows trước khi dùng workflow có slash
command:

| Điều kiện | Cách xác nhận | Lý do |
|---|---|---|
| OpenCode đã mở hoặc reload dự án | Mở thư mục gốc dự án trong OpenCode sau khi thêm `.opencode/commands/`. | OpenCode cần nạp các slash command của dự án. |
| Node.js và npm hoạt động | `node --version` và `npm --version` trả về phiên bản. | OpenSpec CLI được cài qua npm. |
| OpenSpec CLI đúng phiên bản | `openspec --version` trả về `1.5.0`. | Các command bootstrap gọi trực tiếp executable `openspec`. |
| Thư mục dự án có quyền ghi | Có thể tạo/sửa file dự án và chạy lệnh native của dự án. | Artifact OpenSpec, mã nguồn và bằng chứng được lưu trong dự án. |
| Ý tưởng ban đầu | Có thể chỉ là một câu mô tả vấn đề hoặc kết quả mong muốn. | Agent sẽ phỏng vấn để làm rõ phần còn thiếu. |

Cài OpenSpec CLI một lần cho máy hiện tại:

```powershell
npm install --global @fission-ai/openspec@1.5.0
openspec --version
```

Kết quả cần có: lệnh thứ hai in ra phiên bản `1.5.0`. Có thể dùng
`npx --yes @fission-ai/openspec@1.5.0` cho một lệnh CLI riêng lẻ, nhưng không
thay thế cài đặt global khi dùng `/opsx-*`, vì các slash command gọi lệnh trần
`openspec`.

## 2. Khởi Tạo Một Dự Án Tham Gia

Mở session tại thư mục gốc của dự án và yêu cầu agent khởi tạo SDD. Với dự án
mới, agent dùng toàn bộ bootstrap. Với dự án đã có tài liệu hoặc `openspec/`,
agent phải đối chiếu từng file và hợp nhất có chủ đích, không ghi đè lịch sử.

1. Gửi yêu cầu trong session:

   ```text
   Khởi tạo SDD cho dự án này. Hãy kiểm tra file hiện có, áp dụng bootstrap an
   toàn, chạy preflight và phỏng vấn tôi về thông tin sản phẩm còn thiếu. Không
   yêu cầu tôi tự sửa file.
   ```

2. Với dự án mới, agent có thể dùng lệnh sau để lấy cả `.opencode/` mà không
   dùng `-Force`:

   ```powershell
   Get-ChildItem -LiteralPath 'D:\Projects\SDD\templates\project' -Force |
     Copy-Item -Destination . -Recurse
   ```

3. Agent đọc dự án và phỏng vấn từng câu quan trọng để tự cập nhật `PRODUCT.md`.
   Nếu có UI hoặc quyết định bền vững, agent tự duy trì `DESIGN.md`; nếu cần
   context OpenSpec hay `AGENTS.md`, agent cũng tự cập nhật sau khi xác minh.

4. Khởi động lại hoặc reload OpenCode để nhận các file trong
   `.opencode/commands/`.

5. Yêu cầu agent chạy preflight của bootstrap:

   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\Test-OpenSpecBootstrapPreflight.ps1
   ```

   Preflight phải thành công trước slash command đầu tiên. Agent tự xử lý hoặc
   giải thích warning của profile `core`; không giao người dùng sửa command.

### Nâng Cấp Dự Án Đã Dùng SDD

Các dự án đã sao chép bootstrap trước thay đổi này vẫn giữ command cũ. Trong
session của dự án đó, gửi:

```text
Đồng bộ workflow SDD session-first mới nhất từ
D:\Projects\SDD\templates\project. Chỉ cập nhật năm file opsx command và
preflight sau khi xem diff; không ghi đè PRODUCT.md, DESIGN.md, PACKAGE.md,
openspec/changes hoặc dữ kiện dự án. Chạy preflight sau khi cập nhật.
```

Agent phải xem diff, chỉ cập nhật bề mặt framework được nêu, chạy preflight và
yêu cầu reload OpenCode. Người dùng không cần tự sao chép hay sửa file.

### Khởi Tạo Không Dùng Bootstrap

Nếu không sao chép template, tạo tích hợp OpenSpec core tương đương tại root dự
án bằng:

```powershell
npx --yes @fission-ai/openspec@1.5.0 init --tools opencode --profile core
```

Lệnh này không tạo `PRODUCT.md`, `DESIGN.md`, `PACKAGE.md` hay preflight riêng
của SDD. Nếu muốn dùng toàn bộ workflow, yêu cầu agent lấy các template còn
thiếu từ `templates/project/` và hợp nhất an toàn.

### Dự Án Dùng OpenSpec Store

Mặc định, lệnh OpenSpec làm việc với thư mục `openspec/` gần nhất. Nếu dự án
làm việc trong một OpenSpec store đã đăng ký, tìm ID store trước:

```powershell
openspec store list --json
```

Dùng ID trả về ở mọi lệnh đọc hoặc ghi change/spec, ví dụ:

```powershell
openspec list --store <store-id> --json
openspec new change <change-name> --store <store-id> --json
openspec status --change <change-name> --store <store-id> --json
openspec instructions apply --change <change-name> --store <store-id> --json
openspec validate <change-name> --store <store-id> --strict --no-interactive
openspec archive <change-name> --store <store-id> --skip-specs --yes
openspec archive <change-name> --store <store-id> --yes
```

Lệnh archive đầu dùng khi `/opsx-sync` đã merge delta; lệnh thứ hai dùng khi
delta chưa sync để OpenSpec cập nhật main spec đúng một lần. Lệnh local bỏ hoàn
toàn `--store <store-id>`. Giữ cùng một store ID ở mọi lệnh tiếp theo mà CLI gợi
ý. Các slash command
`/opsx-*` cũng thực hiện bước chọn store khi bạn nêu store hoặc change thuộc
store; không trộn artifact của store với `openspec/` cục bộ.

## 3. Chọn Chế Độ Làm Việc Trước Mỗi Yêu Cầu

Chọn chế độ nhỏ nhất đáp ứng được yêu cầu:

| Tình huống | Cách làm |
|---|---|
| Câu hỏi ngắn hoặc sửa rất rõ | Chat thông thường, không cần Goal hay worktree. |
| Yêu cầu dài, tiêu chí nghiệm thu hoặc feedback có cấu trúc | Dùng Focus Mode; phím tắt Windows mặc định là `Ctrl+Shift+E`. |
| Ý tưởng, nghiên cứu, so sánh chưa chốt | Chat thường hoặc Focus Mode; chưa tạo Session Goal. |
| Triển khai ghi code nhiều bước đã chốt phạm vi và lệnh hoàn thành | Tạo worktree qua OpenChamber, rồi tự bật Session Goal nếu muốn. |
| Chạy kiểm tra read-only nhiều bước | Có thể dùng Goal mà không cần tạo worktree mới. |
| Session đã ở trong worktree cô lập | Có thể dùng Goal nếu mọi quyết định và cách kiểm tra đã rõ. |
| So sánh các phương án UI/kiến trúc thực sự độc lập | Dùng MultiRun; mỗi phương án phải ở worktree riêng. |
| Chuẩn bị release | Goal chỉ được chạy đến trạng thái `ready for release`. |

Sau mỗi bước, agent phải trả về hai dòng: `Bước tiếp theo:` với command hoặc
session action cụ thể và `Cách làm phù hợp:` với chế độ nên dùng cùng
lý do ngắn. Bạn không cần tự nhớ toàn bộ chuỗi command.

Chỉ bật Session Goal khi có đủ: kết quả quan sát được, phạm vi cụ thể, lệnh/bằng
chứng hoàn thành, quyết định sản phẩm/UI đã chốt, điều kiện bị chặn đã rõ, writer
không chồng lấn và không có external action chưa phê duyệt. Công việc ghi code
phải nằm trong worktree; Goal đơn lẻ chỉ dùng cho read-only/deterministic work
hoặc session đã ở worktree. Mẫu objective:

```text
Objective: <kết quả hoàn thành có thể quan sát>.
Scope: chỉ <file, capability hoặc worktree được phép>.
Completion evidence: <lệnh kiểm tra chính xác và kết quả mong đợi>.
Constraints: <ràng buộc đã phê duyệt>.
Blocked only when: <điều kiện chặn cụ thể>.
Do not: publish, deploy, tag, merge, purchase, delete, hoặc thay đổi trạng thái bên ngoài.
```

Khi Goal đang `Evaluating`, không gửi `continue`. Dùng Pause/Stop khi cần dừng;
chỉ Resume sau khi đã giải quyết quyết định hoặc prerequisite đang chặn.

Không dùng Goal khi còn phỏng vấn, brainstorm, research chưa kết luận, chọn UI,
sửa kế hoạch hoặc chờ quyết định về sản phẩm, dữ liệu, bảo mật, chi phí,
credential hay release. Nếu một vấn đề như vậy xuất hiện khi Goal đang chạy,
agent phải pause, báo phần đã xong, giải thích blocker, đưa phương án và chờ bạn.

## 4. Khám Phá Và Chốt Yêu Cầu

Khi ý tưởng chưa đủ rõ để viết code, dùng trong OpenCode:

```text
/opsx-explore <ý tưởng, vấn đề hoặc lựa chọn cần cân nhắc>
```

Ví dụ:

```text
/opsx-explore so sánh SQLite và Postgres cho lịch sử đơn hàng
```

`/opsx-explore` chỉ dùng để suy nghĩ, tra cứu và đọc mã; nó không triển khai mã
nguồn. Agent chủ động phỏng vấn theo chủ đề, không giới hạn cứng số câu hay số
lượt, trình bày phương án theo nhóm dễ so sánh, khuyến nghị một hướng và tự ghi
artifact sau khi bạn xác nhận. Kết thúc bước này khi đã chốt được:

- Vấn đề, người dùng và kết quả mong muốn.
- Phạm vi và non-goals.
- Tiêu chí chấp nhận có thể kiểm chứng.
- Ràng buộc như UI, dữ liệu, bảo mật, chi phí hoặc deadline.
- Các điểm còn mơ hồ cần bạn quyết định.

Với dependency, SDK, API hoặc dịch vụ bên ngoài, yêu cầu agent thu thập Context7
evidence theo đúng phiên bản trước khi chọn API hoặc thêm dependency. Với mã
hiện có, yêu cầu agent khảo sát cấu trúc và ảnh hưởng trước khi đề xuất thay đổi.

## 5. Tạo Change Và Artifact

Khi yêu cầu đã đủ rõ, tạo change:

```text
/opsx-propose <tên-change-kebab-case hoặc mô tả yêu cầu>
```

Ví dụ:

```text
/opsx-propose add-status-endpoint
```

Hoặc:

```text
/opsx-propose thêm endpoint trả về trạng thái dịch vụ cho hệ thống giám sát
```

Command sẽ tạo change, đọc thứ tự artifact từ CLI và chuẩn bị các artifact cần
thiết trước khi triển khai. Đừng tự giả định tên/path artifact: schema có thể
trả về path khác. Dùng lệnh sau để xem trạng thái thực tế:

```powershell
openspec status --change <change-name> --json
```

Agent tự tạo và cập nhật các artifact theo path do OpenSpec trả về. Bạn không
cần mở hoặc điền chúng. Vai trò của từng artifact:

| Artifact | Khi nào cần | Yêu cầu nội dung |
|---|---|---|
| `proposal.md` | Mọi change | Vấn đề, thay đổi dự kiến, phạm vi và non-goals. |
| `specs/<capability>/spec.md` | Mọi hành vi mới/sửa đổi | Requirement chuẩn tắc và scenario WHEN/THEN có thể kiểm chứng. |
| `design.md` | Change cần quyết định kỹ thuật | Cách làm, ràng buộc, risk, rollback và verification path. |
| `tasks.md` | Trước triển khai | Task có phạm vi, thứ tự và acceptance check. |
| `research.md` | Có external API/dependency, source behavior hoặc claim chưa rõ | Nguồn, phiên bản, bằng chứng và quyết định. |
| `verification.md` | Trước khi kết luận hoàn thành | Lệnh đã chạy, coverage requirement, kết quả và giới hạn. |
| `release.md` | Có package/deploy/publish/external write | Approval, kết quả release và post-release smoke. |

Khi OpenSpec báo thiếu artifact hoặc `/opsx-apply` ở trạng thái `blocked`, agent
tự khôi phục theo đúng schema thay vì yêu cầu bạn tạo file:

```powershell
openspec status --change <change-name> --json
openspec instructions <artifact-id> --change <change-name> --json
```

Đọc toàn bộ `contextFiles` mà lệnh `instructions` trả về, tạo/cập nhật đúng
`resolvedOutputPath`, rồi chạy lại `status`. Lặp đến khi `instructions apply`
trả về `ready` hoặc `in_progress`:

```powershell
openspec instructions apply --change <change-name> --json
```

## 6. Rà Soát Kế Hoạch Và Cổng Quyết Định

Trước khi code, kiểm tra proposal/spec/design/tasks có đồng nhất và thay đổi có
đụng một trong các ranh giới sau không:

- Runtime dependency hoặc external service chưa được duyệt.
- Public API, schema, data lifecycle hoặc migration.
- Auth, payment, privacy hoặc security.
- Hướng UI đã duyệt.
- Chi phí, thời gian, phạm vi hoặc release target/rollback plan tăng đáng kể.
- Hành động phá hủy hoặc không thể đảo ngược.

Nếu có, dừng để xin quyết định rõ ràng trước khi triển khai. Không cần xin lại
quyết định cho việc đọc mã, refactor cục bộ, test tập trung hoặc sửa lỗi nằm
trong kế hoạch đã duyệt.

Với UI mới hay redesign đáng kể, trước khi code cần chọn một hướng giao diện.
Ghi hướng đã chọn vào `docs/surfaces/<surface>.md`; file này chỉ mô tả composition
và tương tác của surface, không lặp lại product truth hoặc design token đã có.

## 7. Triển Khai Theo Tasks

Bắt đầu triển khai bằng:

```text
/opsx-apply <change-name>
```

Ví dụ:

```text
/opsx-apply add-status-endpoint
```

Nếu bỏ tên change, command chỉ tự chọn khi ngữ cảnh không mơ hồ hoặc chỉ có một
change active. Nếu có nhiều change, hãy chỉ định tên để tránh làm sai phạm vi.

Trong lúc triển khai, command cần:

1. Đọc `openspec status` và `openspec instructions apply`.
2. Đọc tất cả context file được CLI trả về.
3. Làm từng task trong `tasks.md` với phạm vi tối thiểu.
4. Cập nhật checkbox `- [ ]` thành `- [x]` ngay sau khi task hoàn thành.
5. Chạy kiểm tra tập trung gắn với task.
6. Dừng khi task mơ hồ, có blocker hoặc phát hiện cần thay đổi design/spec.

Đối với bug hồi quy, API công khai, parser/serializer, state transition, bảo
mật, validation, tiền, dữ liệu, migration, concurrency hoặc logic nghiệp vụ
không đơn giản, thêm hay cập nhật focused regression test trước khi sửa nếu khả
thi. Với tài liệu, config đơn giản, rename cơ học hoặc CSS nhỏ, ghi bằng chứng
trực tiếp phù hợp thay vì tạo kiểm thử giả tạo.

Nếu hai lần sửa liên tiếp không giải quyết được cùng một vấn đề, không tiếp tục
sửa theo cảm tính. Cần đánh giá lại log, giả định, reproduction, tài liệu API,
phạm vi hoặc nguyên nhân gốc trước khi thử hướng thứ ba.

## 8. Xác Minh Thay Đổi

Sau task cuối cùng, chạy các lệnh native được khai báo bởi dự án, chẳng hạn test,
lint, type check, build hoặc browser/accessibility check. Không sao chép một lệnh
ví dụ từ dự án khác vào bằng chứng.

Validate change bằng OpenSpec strict mode:

```powershell
openspec validate <change-name> --strict --no-interactive
```

`npx --yes @fission-ai/openspec@1.5.0 validate <change-name> --strict --no-interactive`
cũng hợp lệ cho lần validate độc lập. Dùng output thực tế để sửa artifact có lỗi
hoặc warning; không đánh dấu hoàn thành nếu lệnh bắt buộc trả về exit code khác
`0`.

Agent tự điền `<changeRoot>/verification.md` với:

- Tên change, commit và ngày.
- Kết quả strict validation.
- Từng lệnh đã chạy, exit code/kết quả và phạm vi lệnh chứng minh.
- Mapping từng requirement sang test hoặc bằng chứng trực tiếp.
- Package evidence nếu có artifact.
- Điều chưa được chứng minh hoặc kiểm tra chưa khả dụng.

Với UI, bổ sung screenshot desktop và narrow mobile, viewport, browser behavior,
console/network, accessibility/keyboard evidence nếu dự án có công cụ tương
ứng. Sau review ảnh độc lập và machine checks đạt, trạng thái chỉ là
`READY-FOR-HUMAN-APPROVAL`; hãy phê duyệt thị giác rõ ràng trước khi ghi
`UI-APPROVED`.

## 9. Đồng Bộ Delta Spec

Khi cần chuyển delta spec của một change vào specification chính, dùng:

```text
/opsx-sync <change-name>
```

Command đọc delta spec từ path do `openspec status` trả về và áp dụng các phần
`ADDED`, `MODIFIED`, `REMOVED`, `RENAMED` vào `openspec/specs/`. Nếu không chỉ
định change, command phải yêu cầu bạn chọn; không nên đoán change cần sync.

`/opsx-sync` là lần merge delta thủ công duy nhất. Khi archive change đã sync,
phải dùng `openspec archive <change-name> --skip-specs --yes`; nếu chưa sync,
không merge thủ công trong archive mà dùng
`openspec archive <change-name> --yes` để CLI cập nhật spec một lần.

Việc sync không thay thế cổng hoàn thành, verification, release hay archive.

## 10. Đóng Gói

Trước lần package đầu tiên, agent đọc project tooling, phỏng vấn các dữ kiện
release chưa thể suy ra và tự điền `PACKAGE.md` với:

1. Version dự kiến, lệnh build/package, artifact hoặc runtime entry point và
   lệnh kiểm tra version.
2. Cách tạo temporary environment mới, lệnh install/run và smoke command.
3. Danh sách file development phải vắng mặt, cách quét dấu hiệu nhạy cảm và nơi
   lưu SHA-256.
4. External action dự kiến, target, post-release smoke, rollback và điều kiện
   chặn archive.

Sau đó chạy đúng các lệnh đã khai báo và chỉ coi artifact sẵn sàng khi mọi điều
kiện sau đều có bằng chứng mới:

- Build/package trả về exit code `0`.
- Artifact/entry point tồn tại và version đúng.
- Artifact cài hoặc chạy được trong thư mục temporary mới, không tái dùng source
  tree, dependency, build output, login state hay environment file cũ.
- Minimal smoke test trả về exit code `0`.
- File development không bị đưa vào; quét file-name/nội dung không phát hiện
  credential material.
- SHA-256 của chính artifact đã kiểm tra được ghi lại.

Agent ghi kết quả vào `<changeRoot>/verification.md` và
`<changeRoot>/release.md` của change.

## 11. Phát Hành Có Phê Duyệt

Goal có thể chuẩn bị release bằng cách build/package, kiểm tra artifact trong
môi trường sạch, chạy smoke test, tính checksum, soạn release notes, tổng hợp
cảnh báo và chuẩn bị rollback plan. Khi các bước này đạt, Goal phải dừng ở trạng
thái `ready for release` và trình bày release-ready summary.

Goal không được publish, deploy, tag, push, merge, thay đổi production hoặc
archive. Trước bất kỳ external write nào, cần phê duyệt rõ ràng cho cùng một bộ
giá trị:

| Bắt buộc được phê duyệt | Ví dụ |
|---|---|
| Version | `1.4.0` |
| Release notes | Nội dung release notes cuối cùng |
| Target/environment | `production`, registry hoặc nhánh cụ thể |
| Known warnings | Cảnh báo đã biết hoặc xác nhận không có |
| Rollback plan | Lệnh/quy trình quay về artifact trước đó |
| Exact external action | Lệnh publish/deploy/tag/push/merge cụ thể |

Agent ghi nguyên văn approval, người phê duyệt và ngày vào
`<changeRoot>/release.md`. Approval cho version, target hoặc lệnh khác không áp
dụng lại được. Exact external action chạy ngoài Goal boundary. Khi action được
duyệt và chạy xong, agent ghi command, exit code, URL/identifier nếu có và kết
quả post-release smoke. Nếu thất bại, agent ghi `BLOCKED`, giữ change active và
chỉ thực hiện rollback khi bạn chỉ đạo.

## 12. Archive Change

Archive chỉ thực hiện khi mọi artifact/task hoàn tất, requirement coverage đầy
đủ, strict validation tươi chạy sau external action (nhánh release) hoặc sau
fresh focused validation (nhánh no-external-release), và `releaseApplicable`
được quyết định từ evidence thực tế.

Có slash command sau:

```text
/opsx-archive <change-name>
```

Command SDD đã được điều chỉnh để dùng trực tiếp CLI portable trên Windows và
không tự tạo thư mục archive. Source guard chính áp dụng hai nhánh:

- **Release-applicable** khi change đụng `PACKAGE.md`, package/deploy/
  publish/tag/push/merge/external write trong proposal/design/tasks, hoặc
  `release.md` đã ghi external action/result. Yêu cầu version/notes/target/
  warnings/rollback/exact external action + approval cùng bộ giá trị, external
  action thành công, post-release smoke `0`, và strict validation `0`.
- **No-external-release** chỉ hợp lệ khi không có release indicator và đã
  hoàn tất mọi gate: completed tasks/artifacts, full requirement coverage,
  fresh focused validation `0`, strict validation `0`, và
  `releaseApplicable: false` kèm reason trong `verification.md`. User
  confirmation không thể vượt gate; ghi giả `RELEASED-OK` hoặc fake
  approval/result là cấm.

Cả hai nhánh chọn đúng một trong bốn lệnh portable sau dựa trên root và
trạng thái sync, luôn dùng `--yes` (và `--skip-specs` nếu đã sync):

```powershell
openspec validate <change-name> --strict --no-interactive
openspec archive <change-name> --skip-specs --yes
# Hoặc, nếu delta chưa sync:
openspec archive <change-name> --yes
```

Với store, giữ cùng `--store <store-id>` trên validate và archive. Lệnh local
bỏ hoàn toàn `--store`.

Không tự tạo thư mục archive hoặc di chuyển change directory thủ công. Không
archive change bị fail, cancelled, unapproved, hoặc thiếu gate trong bất kỳ
nhánh nào.

## 13. Bảng Lệnh Tham Khảo Nhanh

| Lệnh | Khi dùng | Yêu cầu đầu vào/kết quả |
|---|---|---|
| `/opsx-explore [nội dung]` | Phỏng vấn, brainstorm, onboarding sản phẩm | Agent tự cập nhật product/design facts đã xác nhận; không code. |
| `/opsx-propose <name/mô tả>` | Bắt đầu change | Agent tự phỏng vấn và tạo mọi artifact apply-ready. |
| `/opsx-apply [change-name]` | Hoàn thiện artifact, code và verify | Agent tự sửa file, chạy check, tick task và ghi verification. |
| `/opsx-sync <change-name>` | Đồng bộ delta spec | Agent tự merge vào main specs và tư vấn bước tiếp theo. |
| `/opsx-archive <change-name>` | Rà release gate và archive | Agent tự duy trì evidence; người dùng chỉ explicit approval trong session. |
| `openspec list --json` | Xem change active | Dùng khi cần chọn change. |
| `openspec status --change <name> --json` | Xem artifact/path/trạng thái thực tế | Là nguồn sự thật cho artifact và path. |
| `openspec instructions <id> --change <name> --json` | Hoàn thành artifact thiếu | Dùng `id` do `status` trả về. |
| `openspec instructions apply --change <name> --json` | Xem context và trạng thái apply | `ready`/`in_progress` mới có thể triển khai. |
| `openspec validate <name> --strict --no-interactive` | Trước khi kết luận/archive | Exit code phải là `0`. |
| `openspec archive <name> --skip-specs --yes` | Lưu trữ change đã sync | Không áp dụng delta lần hai. |
| `openspec archive <name> --yes` | Lưu trữ change chưa sync | Để OpenSpec cập nhật main spec đúng một lần. |

## 14. Xử Lý Sự Cố Thường Gặp

| Triệu chứng | Cách xử lý |
|---|---|
| `openspec` không được nhận diện | Cài lại đúng bản global, chạy `openspec --version`, mở lại terminal/OpenCode. |
| Preflight báo sai phiên bản | Cài chính xác `@fission-ai/openspec@1.5.0`; không dùng bản khác cho slash command. |
| Không thấy `/opsx-*` | Xác nhận `.opencode/commands/` đã được sao chép, rồi reload/restart OpenCode. |
| `/opsx-apply` báo `blocked` | Agent tự chạy `status` và `instructions <artifact-id>`, tạo artifact đúng `resolvedOutputPath`; bạn chỉ trả lời nếu thiếu quyết định material. |
| Strict validation thất bại | Agent tự sửa artifact theo output và chạy lại validation; không archive khi kiểm tra bắt buộc còn lỗi. |
| Goal hết budget hoặc bị block | Agent tóm tắt phần đã xong/còn lại và blocker; bạn chọn giải quyết, thu nhỏ, resume hoặc dừng. Agent không tự tăng budget hay resume. |
| Cần thay đổi API, dependency, data, security hoặc release target | Agent đưa phương án, xin quyết định rõ ràng, rồi tự cập nhật proposal/spec/design. |
| Artifact chạy trong source tree nhưng không chạy sạch | Agent giữ change active, sửa package contract/artifact và làm lại clean-environment smoke. |
| Archive trên Windows gặp `ResourceExists` | Không tạo thư mục tay; chạy archive noninteractive đúng nhánh sync sau khi qua toàn bộ gate. |

## 15. Tiêu Chí Hoàn Thành Của Một Change

Một change chỉ có thể được coi là hoàn thành khi tất cả điều kiện áp dụng đều
đạt:

- Artifact OpenSpec bắt buộc hoàn chỉnh và strict validation pass.
- Toàn bộ task đã tick, mã nguồn nằm trong phạm vi đã duyệt.
- Requirement có test hoặc bằng chứng trực tiếp tương ứng.
- Lệnh project-native liên quan có kết quả thành công được ghi lại.
- Với UI: có evidence phù hợp và phê duyệt thị giác rõ ràng nếu cần.
- Với package/release: package gate, exact approval, external result và
  post-release smoke đã được ghi lại.
- Những điều chưa xác minh được ghi là giới hạn, không bị mô tả là PASS.

Sau release thành công và archive, chi tiết active change được lưu bởi OpenSpec;
`PRODUCT.md`, `DESIGN.md` và specification chính vẫn là bộ nhớ bền vững để bắt
đầu thay đổi tiếp theo.
