# SDD - Khung Quy Trình Phát Triển Với OpenCode

SDD (Spec-Driven Development) là khung quy trình cá nhân cho OpenCode và
OpenChamber. Khung dẫn dắt một thay đổi từ ý tưởng, đặc tả, triển khai và kiểm
chứng đến chuẩn bị phát hành; đồng thời giữ quyền quyết định sản phẩm và quyền
phát hành ở người dùng.

Đây là source repository của một framework cá nhân tại `D:\Projects\SDD`.
Mã nguồn và source-release asset được lưu công khai trên GitHub, nhưng runtime,
credential và cấu hình active vẫn thuộc môi trường riêng của chủ sở hữu. Đây
không phải gói npm, extension marketplace hay sản phẩm đa người dùng. Tài liệu
dùng framework trong một dự án nằm tại
[HUONG-DAN-SU-DUNG.md](HUONG-DAN-SU-DUNG.md).

## Trạng Thái Phiên Bản

| Bề mặt | Trạng thái |
|---|---|
| Stable source release | `v0.1.0`, phát hành ngày 2026-08-12 từ payload bất biến `a431be0064dc5b84abc31bb60fcbb94eaa185661`. |
| Nhánh phát triển đang được kiểm chứng | Commit `e5bb0ed775a6c1340089a0f299c6699ac533bf20` bổ sung global apply readiness preflight và đã qua CI. |
| Runtime cá nhân | Không được đóng gói trong release; phải được kiểm tra và áp dụng riêng theo runbook. |

Stable `v0.1.0` cố ý giữ nguyên payload đã được chấp nhận từ RC. Vì vậy các
release-automation commit và global-readiness preflight được thêm sau payload
SHA không nằm trong ZIP stable. Khi đọc tài liệu trên nhánh mới hơn, hãy kiểm tra
file/lệnh có thực sự tồn tại trong bản source đang dùng.

## Mục Tiêu

- Biến yêu cầu thành thay đổi có phạm vi, tiêu chí hoàn thành và bằng chứng rõ
  ràng.
- Dùng đặc tả làm ngữ cảnh bền vững của dự án thay vì phụ thuộc vào lịch sử
  chat.
- Cho phép người dùng làm việc hoàn toàn qua session: agent phỏng vấn, đề xuất
  phương án và tự duy trì mọi artifact; người dùng không phải mở hay sửa file.
- Chỉ tăng mức điều phối, nghiên cứu hoặc kiểm thử khi rủi ro thực sự cần.
- Không cho phép tự động xuất bản, triển khai, gắn thẻ, merge, mua hàng hoặc
  thao tác phá hủy.
- Dùng lệnh thực tế và kết quả quan sát được thay cho tuyên bố "đã xong" của
  agent.

## Tính Năng

### Quy Trình Theo Đặc Tả

Mỗi dự án tham gia có một bootstrap OpenSpec cục bộ. Thay đổi đi qua chuỗi hiện
vật sau, với mức tài liệu tối thiểu phù hợp cho thay đổi nhỏ và đầy đủ hơn cho
thay đổi có rủi ro:

```text
Ý tưởng
  -> proposal.md
  -> research.md (khi cần bằng chứng)
  -> specs/<capability>/spec.md
  -> design.md
  -> tasks.md
  -> mã nguồn + kiểm thử
  -> verification.md
  -> gói phát hành + release.md (khi có external release)
  -> hoặc releaseApplicable: false (khi thực sự không có external release)
  -> OpenSpec archive
```

OpenSpec quản lý đề xuất, delta specification, kế hoạch và công việc; mã nguồn,
lệnh build/test và dữ kiện sản phẩm luôn thuộc về chính dự án.

### Tự Động Hóa Qua Session

Người dùng không cần điền `PRODUCT.md`, `DESIGN.md`, `PACKAGE.md`, surface brief
hoặc OpenSpec artifact. Agent thực hiện toàn bộ thao tác file và chỉ yêu cầu
người dùng cung cấp ý định, chọn phương án hoặc phê duyệt trong session:

- `/opsx-explore` phỏng vấn thích ứng theo độ phức tạp, trình bày các phương án
  theo nhóm dễ so sánh, khuyến nghị một hướng và tự ghi product/design facts đã
  xác nhận.
- `/opsx-propose` tự tạo change và toàn bộ artifact cần để apply.
- `/opsx-apply` tự hoàn thiện artifact bị thiếu, triển khai task, chạy kiểm tra
  và ghi `verification.md` dưới change root.
- `/opsx-sync` tự hợp nhất delta spec vào specification chính.
- `/opsx-archive` tự quản lý verification/release evidence và chỉ dừng để lấy
  explicit approval cho hành động bên ngoài.

Sau mỗi bước hoặc khi bị chặn, agent luôn nêu `Bước tiếp theo:` và
`Cách làm phù hợp:` để chỉ rõ command/session action tiếp theo và có
nên dùng Focus Mode, Session Goal, worktree, MultiRun hay không.

Phỏng vấn không bị giới hạn cứng bởi số câu, số lượt hoặc số phương án. Agent
dùng fast path khi yêu cầu đã rõ, hỏi theo từng chủ đề liên quan khi còn thiếu,
tóm tắt sau mỗi vòng và dừng khi mục tiêu, phạm vi, ràng buộc, quyết định mở và
cách kiểm chứng đã đủ để lập kế hoạch an toàn.

### Điều Phối Agent Có Ranh Giới

Lớp `oh-my-opencode-slim` định tuyến các vai trò chuyên biệt, không biến mỗi
thay đổi thành một dàn agent độc lập:

| Vai trò | Trách nhiệm chính |
|---|---|
| Orchestrator | Phân loại yêu cầu, quyết định mức công việc, điều phối và đối chiếu bằng chứng. |
| Explorer | Tìm cấu trúc, quan hệ và điểm ảnh hưởng trong mã cục bộ. |
| Librarian | Thu thập bằng chứng phiên bản cho API, SDK và dependency bên ngoài. |
| Fixer | Triển khai thay đổi có phạm vi và chạy kiểm tra tập trung. |
| Designer | Triển khai, rà soát UI theo hướng thiết kế đã phê duyệt. |
| Observer | Phân tích ảnh, ảnh chụp màn hình, sơ đồ và OCR ở ngữ cảnh cô lập. |
| Oracle | Đánh giá kiến trúc, gỡ lỗi khó hoặc rủi ro đáng kể theo phạm vi cụ thể. |

Các agent chỉ đọc như Explorer, Librarian, Oracle và Observer bị giới hạn quyền
ghi. Fixer/Designer chỉ nhận task brief có kết quả quan sát được, phạm vi file,
tiêu chí chấp nhận và lệnh kiểm tra phù hợp.

### Nghiên Cứu Dựa Trên Nguồn

- Context7 cung cấp tài liệu API/dependency theo thư viện và phiên bản đã chọn.
- CodeGraph phục vụ kiến trúc, caller/callee, luồng chạy và phân tích ảnh hưởng
  khi chỉ mục hoạt động tốt.
- Glob, Grep và Read phục vụ nội dung chính xác, cấu hình, tài liệu, file sinh
  ra hoặc file chưa được chỉ mục.
- Nếu bằng chứng bên ngoài không truy xuất được, framework ghi nhận giới hạn;
  không âm thầm thay thế bằng trí nhớ mô hình cho quyết định nhạy cảm.

### Thực Thi Và Khắc Phục Có Kiểm Soát

- Mỗi task được giới hạn theo kết quả, phạm vi, bất biến và kiểm tra cần chạy.
- Thay đổi đơn giản, file đã biết và tiêu chí rõ ràng được thực hiện trực tiếp.
- TDD red-green được ưu tiên cho bug hồi quy, API công khai, trạng thái, dữ
  liệu, bảo mật, migration, đồng thời và logic nghiệp vụ không tầm thường.
- Sau hai lần sửa không thành công, agent dừng sửa mù quáng để đánh giá lại giả
  định hoặc nguyên nhân gốc; Oracle chỉ được dùng khi rủi ro biện minh cho nó.
- Kết quả kiểm tra thất bại không thể được ghi là PASS.

### Điều Khiển Phiên Làm Việc

OpenChamber là control plane duy nhất cho project, session, Focus Mode, Session
Goal, worktree và MultiRun:

- Focus Mode phù hợp để nhập yêu cầu dài, tiêu chí chấp nhận hoặc phản hồi UI.
- Worktree + Session Goal phù hợp cho công việc ghi code nhiều bước đã có điểm
  kết thúc và bằng chứng hoàn thành cụ thể.
- Goal không cần tạo worktree mới chỉ phù hợp cho công việc read-only/xác định,
  hoặc session vốn đã ở trong một worktree cô lập.
- Worktree cô lập phần triển khai có nguy cơ xung đột với nhánh làm việc chính.
- MultiRun chỉ dùng để so sánh các phương án độc lập trong worktree riêng.

Framework chỉ khuyến nghị chế độ phù hợp; không tự bật Goal, tăng ngân sách,
tiếp tục Goal, tạo worktree hoặc chấp nhận quyền thay người dùng.

Trong release, Goal chỉ được chuẩn bị đến `ready for release`: build/package,
kiểm tra artifact, clean smoke, checksum, release notes, cảnh báo và rollback.
Goal phải dừng trước publish, deploy, tag, push, merge, thay đổi production hoặc
archive. Các bước đó chỉ chạy sau explicit approval cho đúng bộ giá trị.

### Chất Lượng Giao Diện

Với UI mới hoặc thiết kế lại đáng kể, khung áp dụng chuỗi thẩm quyền:

```text
PRODUCT.md -> DESIGN.md -> docs/surfaces/<surface>.md -> task triển khai
```

Quy trình phân biệt rõ giữa kiểm tra máy, ảnh desktop/mobile, kiểm tra browser
và accessibility, review ảnh độc lập, với phê duyệt thị giác cuối cùng của
người dùng. Điểm đánh giá tổng hợp hoặc detector sạch không phải bằng chứng đủ
để tuyên bố giao diện đã được phê duyệt.

### Hỗ Trợ Đa Phương Tiện

Metadata của MiniMax M3 có khai báo khả năng image/video, nhưng structured
attachment đã được framework triển khai và smoke-test hiện chỉ hỗ trợ PNG,
JPEG, GIF và WebP cho ảnh, screenshot, sơ đồ và OCR. Chưa công bố verified video
handoff. Route GPT hiện được quản lý như text-only; framework không quảng cáo
khả năng PDF qua M3. Tài liệu PDF cần đi qua text extraction, chuyển trang thành
ảnh hoặc một route PDF đã được xác minh.

### Kiểm Chứng, Đóng Gói Và Phát Hành

- `verification.md` liên kết từng yêu cầu với kiểm thử hoặc bằng chứng trực
  tiếp, đồng thời ghi lại giới hạn còn lại.
- `PACKAGE.md` mô tả lệnh build/package, artifact, smoke test trong môi trường
  sạch, kiểm tra nội dung, checksum SHA-256 và rollback của từng dự án.
- Artifact phải build thành công, tồn tại đúng vị trí, đúng phiên bản, chạy hoặc
  cài được trong môi trường mới, qua smoke test và kiểm tra nội dung trước khi
  sẵn sàng phát hành.
- Mọi publish, deploy, tag, push, merge hay external write cần phê duyệt rõ ràng
  cho đúng version, release notes, target, cảnh báo, rollback plan và hành động.
- Change có external release chỉ được archive sau khi external action và
  post-release smoke thành công. Change thực sự không có external release chỉ
  được archive sau focused verification, strict validation và bản ghi
  `releaseApplicable: false` có lý do.

### An Toàn Vận Hành

- Cấu hình toàn cục, xác thực, session, relay state và backup nhạy cảm không
  được sao chép vào kho này.
- Mỗi thay đổi cấu hình toàn cục cần xác định owner, target, cơ chế ghi được hỗ
  trợ, backup theo file, checksum, lệnh xác minh và rollback trước khi áp dụng.
- Trước mọi backup, persistent write hoặc restart của runtime toàn cục, chạy
  read-only global readiness preflight. `NO_APPLY_REQUIRED` nghĩa là không chạy
  apply; `READY_FOR_GLOBAL_APPLY` chỉ cho phép supported drift; `BLOCKED` phải
  dừng. Target bắt buộc bị `ABSENT` hiện luôn là `BLOCKED`.
- GitHub Actions chạy source gate và fixture offline trên Windows cho pull
  request, push vào `main` và manual dispatch; gate không thay thế việc xác minh
  runtime của dự án.
- Các evaluation/failure drill cố định bảo vệ các ranh giới như không false PASS,
  không silent fallback, không fan-out vô hạn và không release không phê duyệt.

## Công Nghệ

| Thành phần | Vai trò trong khung |
|---|---|
| OpenChamber | Quản lý project/session, Focus Mode, Goal, worktree, MultiRun và quyền điều khiển của người dùng. |
| OpenCode | Môi trường agent và công cụ thực thi. |
| oh-my-opencode-slim `2.2.8` | Preset agent gọn nhẹ, định tuyến model, prompt và quyền hạn. |
| OpenSpec `@fission-ai/openspec@1.5.0` | Quản lý thay đổi theo đặc tả và các slash command dự án. |
| Context7 | Tài liệu thư viện/API theo phiên bản. |
| CodeGraph | Đồ thị mã nguồn, luồng gọi và phân tích ảnh hưởng cục bộ. |
| CLIProxy | Provider định tuyến các model GPT-5.6 Terra/Sol trong framework. |
| MiniMax M3 | Model cho retrieval, tìm mã, tác vụ triển khai gọn và phân tích media. |
| PowerShell | Script kiểm tra, preflight, apply có kiểm soát và runtime smoke trên Windows. |
| GitHub Actions | CI Windows cho các regression/source gate. |

## Kiến Trúc

```text
OpenChamber
  Project, session, Focus Mode, Goal, worktree, MultiRun
        |
        v
OpenCode + oh-my-opencode-slim
  Orchestrator, specialist agents, permission và model routing
        |
        +--> Context7: bằng chứng API/dependency bên ngoài
        +--> CodeGraph/Grep/Read: bằng chứng mã nguồn cục bộ
        |
        v
OpenSpec trong từng dự án
  Intent, spec, design, tasks, verification, release history
        |
        v
Lệnh native của dự án
  Test, lint, type check, build, browser check, package smoke
        |
        v
Phê duyệt phát hành rõ ràng của người dùng
```

## Phân Tách Trách Nhiệm

| Nội dung | Nơi lưu và chủ sở hữu |
|---|---|
| Source framework, template, script, evidence | Kho `D:\Projects\SDD`. |
| Cấu hình OpenCode toàn cục | `C:\Users\quang\.config\opencode`, chỉ thay đổi theo owner path đã xác minh. |
| Runtime và settings OpenChamber | `C:\Users\quang\.config\openchamber`, không sao chép hay khôi phục qua framework. |
| Sự thật sản phẩm, dependency, lệnh build/test | Dự án tham gia. |
| Đề xuất và lịch sử thay đổi | `openspec/` của dự án tham gia. |
| Backup bảo vệ | Ngoài workspace framework. |

## Tài Liệu

| Tài liệu | Nội dung |
|---|---|
| [HUONG-DAN-SU-DUNG.md](HUONG-DAN-SU-DUNG.md) | Hướng dẫn sử dụng theo toàn bộ vòng đời một dự án. |
| [CHANGELOG.md](CHANGELOG.md) | Tóm tắt thay đổi theo phiên bản và ranh giới stable/development. |
| [PACKAGE.md](PACKAGE.md) | Hợp đồng đóng gói và phát hành của chính repository SDD. |
| [docs/architecture.md](docs/architecture.md) | Kiến trúc, ownership và ranh giới source/runtime. |
| [docs/operations.md](docs/operations.md) | Vận hành framework, kiểm tra, apply và rollback. |
| [docs/rollback.md](docs/rollback.md) | Quy trình rollback theo phase, target và manifest. |
| [docs/agent-layer.md](docs/agent-layer.md) | Agent, model routing, permission và runtime verification. |
| [docs/model-evals.md](docs/model-evals.md) | Kết quả benchmark model và giới hạn bằng chứng. |
| [docs/openchamber-operating-guide.md](docs/openchamber-operating-guide.md) | Khi dùng Focus Mode, Session Goal, worktree và MultiRun. |
| [docs/ui-quality-layer.md](docs/ui-quality-layer.md) | Bằng chứng chất lượng UI và quy trình phê duyệt thị giác. |
| [docs/packaging-and-release.md](docs/packaging-and-release.md) | Hợp đồng đóng gói, release gate và archive. |
| [docs/evaluation-and-failure-drills.md](docs/evaluation-and-failure-drills.md) | Phạm vi và cách chạy failure drill offline. |
| [PHASE-12-GLOBAL-ROLLOUT.md](PHASE-12-GLOBAL-ROLLOUT.md) | Readiness preflight, controlled apply và rollback cho runtime toàn cục. |
| [release-candidates/v0.1.0-stable-readiness.md](release-candidates/v0.1.0-stable-readiness.md) | Bằng chứng phát hành stable `v0.1.0` và giới hạn còn lại. |
| [PLAN.md](PLAN.md) | Kế hoạch triển khai, quyết định và bằng chứng theo phase. |

## Giới Hạn Cố Ý

- Framework không thay thế package manager, test runner, CI/CD hoặc quy tắc
  nghiệp vụ của một dự án.
- Framework không tự suy đoán lệnh build, test, package hoặc rollback; mỗi dự
  án phải khai báo và xác minh chúng.
- Source gate chỉ chứng minh các policy và fixture của framework, không chứng
  minh mọi phản hồi tương lai của model hoặc runtime của mọi dự án.
- Một dự án chỉ được công bố hay thay đổi trạng thái bên ngoài sau phê duyệt rõ
  ràng của người dùng.
