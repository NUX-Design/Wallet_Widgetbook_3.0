# MCP Production Tasks

สร้างไฟล์เมื่อ: `2026-07-04 12:54:27 +07`
อัปเดตล่าสุดเมื่อ: `2026-07-05 19:16:13 +0700`

เอกสารนี้แตกจาก [mcp-server/PRODUCTION_READY_PLAN.md](mcp-server/PRODUCTION_READY_PLAN.md) ให้เป็น execution checklist สำหรับยกระดับ `flutter-widget-wallet-mcp` ไปสู่ production-ready

## วิธีใช้ไฟล์นี้

- ใช้ checkboxes เพื่อติดตามความคืบหน้าของงานจริง
- ทุกครั้งที่มีการอัปเดตข้อมูลหรือมีความคืบหน้าของงาน ให้ปรับ `อัปเดตล่าสุดเมื่อ` เป็นวันเวลาปัจจุบันทันที
- ถ้างานไหนเริ่มได้พร้อมกัน จะระบุ `Lane`
- ถ้างานไหนควรทำก่อน จะระบุ `Depends on`
- ถ้าปิด task แล้ว ควรแนบหลักฐานอย่างน้อยหนึ่งอย่าง:
  - test file
  - verify script
  - CI workflow
  - doc/update ใน `README.md`, `MAINTENANCE_TH.md`, หรือ `MEMORY.md`

## Requirement Resolution: Remote/Hosted Access

เลือกทาง implement remote HTTP mode จริงตามแผนหลักแล้ว และ phase 6B ด้านล่างคือ execution record ของงานนั้น

## Exit Criteria

- [x] tools หลักทั้งหมดผ่าน acceptance tests
- [x] metadata หลักมี fallback behavior ที่ชัด
- [x] Inspector verification รันได้อัตโนมัติ
- [x] regression tests ครอบทั้ง success และ error paths
- [x] มี CI gate ก่อน merge
- [x] มี client config examples ใช้งานได้จริง
- [x] มี ops/release docs ครบ
- [x] มี evaluation suite ที่รันซ้ำได้
- [x] external user config MCP เข้าถึง GitHub-hosted source of truth ได้จาก docs ภายในไม่กี่นาที โดยไม่ต้อง clone repo ทั้งก้อน (plan item 9, line 92)
- [x] ระบุชัดว่า client ไหน supported officially vs generic/best-effort สำหรับ remote-native access (plan item 10, line 93)
- [x] hosted access มี freshness semantics, auth boundary, และ branch/commit targeting ที่ชัดสำหรับ production use (plan item 11, line 94)

## Phase 1: Stabilize Current MCP

### P1-01: Normalize tool contracts

- [x] ทบทวน input/output ของทุก tool ให้ใช้ชื่อ field คงที่
- [x] ทำ shape ของ pagination ให้เหมือนกันใน `list_widgets` และ `search_widgets`
- [x] ระบุ required/optional fields ให้ชัดใน schema ของทุก tool

Depends on: ไม่มี

Lane: Core contracts

### P1-02: Standardize structured output

- [x] ตรวจว่าทุก tool คืน `structuredContent` ในรูปแบบที่สม่ำเสมอ
- [x] ตรวจว่า read-only tools มี annotations ครบ
- [x] แยก success payload กับ error payload ให้ predictable

Depends on: P1-01

Lane: Core contracts

### P1-03: Improve actionable errors

- [x] เพิ่ม error message สำหรับ `widget not found`
- [x] เพิ่ม next-step hints เช่นให้ใช้ `list_widgets` หรือ `search_widgets` ก่อน
- [x] แยก invalid argument, empty result, และ internal failure ให้ชัด

Depends on: P1-01

Lane: Core contracts

### P1-04: Reduce server coupling

- [x] แยก utility functions ที่ปนกันอยู่ใน `mcp-server/index.js`
- [x] ลด coupling ระหว่าง design-system tools กับ widget-library tools
- [x] ย้าย logic ที่ reusable ไปเป็น module แยก

Depends on: P1-01

Lane: Refactor

### P1-05: Freeze tool contract reference

- [x] เขียน contract reference แบบสั้นใน `mcp-server/README.md`
- [x] ระบุ output examples ขั้นต่ำของ tools หลัก
- [x] ยืนยันว่า docs ตรงกับ implementation ปัจจุบัน

Depends on: P1-02, P1-03

Lane: Docs

## Phase 2: Harden Widget Indexing

### P2-01: Split parser responsibilities

- [x] แยกชั้น `filesystem discovery`
- [x] แยกชั้น `Dart parsing`
- [x] แยกชั้น `markdown/doc enrichment`

Depends on: P1-04

Lane: Parser

### P2-02: Improve widget discovery rules

- [x] ลด reliance กับ filename heuristic อย่างเดียว
- [x] รองรับทั้ง `preview_*.dart` และ `*_preview.dart`
- [x] ยืนยันการ map widget -> preview -> docs ในโฟลเดอร์เดียวกัน

Depends on: P2-01

Lane: Parser

### P2-03: Improve metadata extraction

- [x] ดึง props จาก code ให้แม่นขึ้นสำหรับ sample widgets สำคัญ
- [x] ดึง dependencies และ internal imports ให้สม่ำเสมอ
- [x] ดึง assets, Figma links, และ `updatedAt` พร้อม fallback rule

Depends on: P2-01

Lane: Parser

### P2-04: Define precedence and confidence rules

- [x] เขียน precedence rule: `code > widget-local docs > schema/docs overview`
- [x] เพิ่ม confidence/fallback behavior สำหรับ metadata ที่หาไม่ครบ
- [x] เพิ่ม stale detection เมื่อ doc กับ code ขัดกัน

Depends on: P2-02, P2-03

Lane: Parser

### P2-05: Improve search ranking

- [x] กำหนด searchable fields ที่ใช้จริง
- [x] เพิ่ม weighting ระหว่างชื่อ widget, category, tags, docs
- [x] ตรวจ false positive / false negative ของ query พื้นฐาน

Depends on: P2-02, P2-03

Lane: Search

### P2-06: Decide parser depth

- [x] ตัดสินใจว่าจะใช้ regex heuristic ต่อ, tree-sitter, หรือ analyzer-backed parsing
- [x] บันทึกเหตุผลทางเทคนิคและ tradeoff ไว้ใน docs
- [x] ถ้ายังไม่ลงทุน AST ตอนนี้ ให้ระบุ trigger condition ที่จะ revisit

Depends on: P2-01

Lane: Architecture

## Phase 3: Add Test Coverage

### P3-01: Create MCP test harness

- [x] ตั้งโครงสร้าง `mcp-server/tests/` หรือ equivalent
- [x] เลือก test runner และเพิ่ม command ใน `mcp-server/package.json`
- [x] ทำ helper สำหรับเรียก MCP tool calls แบบ integration

Depends on: P1-02

Lane: Test foundation

### P3-02: Add parser fixtures

- [x] สร้าง fixture สำหรับ widget ปกติ
- [x] สร้าง fixture สำหรับหลาย doc files ใน folder เดียว
- [x] สร้าง fixture สำหรับ preview หลากหลาย naming pattern
- [x] สร้าง fixture สำหรับ malformed docs / missing preview

Depends on: P3-01

Lane: Test foundation

### P3-03: Add unit tests for widget catalog

- [x] ทดสอบ filesystem discovery
- [x] ทดสอบ metadata extraction
- [x] ทดสอบ preview/doc matching
- [x] ทดสอบ fallback behavior

Depends on: P2-02, P2-03, P3-02

Lane: Unit tests

### P3-04: Add integration tests for required tools

- [x] `list_categories()`
- [x] `list_widgets(category?, limit?, offset?)`
- [x] `search_widgets(query, limit?)`
- [x] `get_widget_code(widgetName)`
- [x] `get_widget_preview(widgetName)`
- [x] `get_widget_metadata(widgetName)`

Depends on: P3-01, P1-05

Lane: Integration tests

### P3-05: Cover critical error paths

- [x] not found
- [x] empty preview
- [x] malformed docs
- [x] invalid arguments
- [x] category filter edge cases

Depends on: P3-04

Lane: Integration tests

### P3-06: Add output snapshots

- [x] snapshot structured outputs ของ tools หลัก
- [x] snapshot error payload ที่ต้องคงรูปแบบ
- [x] ระบุวิธี update snapshots เมื่อ schema เปลี่ยน

Depends on: P3-04, P3-05

Lane: Snapshot tests

## Phase 4: Inspector + Evaluation Automation

### P4-01: Script Inspector verification

- [x] สร้าง `npm run verify:mcp`
- [x] รัน `tools/list`
- [x] รัน `list_widgets`
- [x] รัน `search_widgets`
- [x] รัน `get_widget_metadata`
- [x] รัน `get_widget_code`
- [x] รัน `get_widget_preview`

Depends on: P3-04

Lane: Verification

### P4-02: Expand evaluation suite

- [x] เพิ่ม case สำหรับ category lookup
- [x] เพิ่ม case สำหรับ search
- [x] เพิ่ม case สำหรับ Figma mapping
- [x] เพิ่ม case สำหรับ source extraction
- [x] เพิ่ม case สำหรับ preview extraction
- [x] เพิ่ม case สำหรับ token lookup

Depends on: P4-01

Lane: Evaluation

### P4-03: Document verification workflow

- [x] เขียนวิธีรัน Inspector checks ใน `mcp-server/README.md`
- [x] เขียนวิธีรัน evaluation suite
- [x] ระบุ expected outputs และ failure hints

Depends on: P4-01, P4-02

Lane: Docs

## Phase 5: CI/CD Gate

### P5-01: Add MCP CI workflow

- [x] syntax check
- [x] automated tests
- [x] Inspector verification
- [x] evaluation smoke run

Depends on: P3-06, P4-02

Lane: CI

### P5-02: Fail on contract regressions

- [x] บังคับให้ CI fail ถ้า tool contract เปลี่ยนโดยไม่มีการอัปเดต expected outputs
- [x] เช็กว่า required tools ยังถูก expose ครบ
- [x] เช็กว่า structured outputs ยัง parse ได้

Depends on: P5-01

Lane: CI

### P5-03: Contributor local parity

- [x] เขียน local runbook ให้รันเหมือน CI ได้
- [x] ระบุคำสั่งขั้นต่ำก่อนเปิด PR
- [x] เช็กว่า developer อ่าน docs แล้วทำตามได้จริง

Depends on: P5-01

Lane: Docs

## Phase 6A: Client Distribution (Local stdio)

### P6A-01: Prepare client config examples

- [x] ตัวอย่าง config สำหรับ Claude Code
- [x] ตัวอย่าง config สำหรับ Codex
- [x] ตัวอย่าง config สำหรับ Cursor ถ้าทีมใช้งาน

Depends on: P1-05

Lane: Distribution

### P6A-02: Improve installer flow

- [x] รองรับ target config มากกว่าหนึ่ง client
- [x] รองรับการระบุ repo root / settings path ชัดเจน
- [x] ตรวจ error cases ของ config file ว่างหรือ malformed

Depends on: P6A-01

Lane: Distribution

### P6A-03: Validate onboarding path

- [x] ทดสอบ onboarding บนเครื่องใหม่ด้วย docs ปัจจุบัน
- [x] วัดว่าตั้งค่าเสร็จได้ภายในไม่กี่นาทีจริง
- [x] แก้ friction points ใน docs/installer

Depends on: P6A-02

Lane: Distribution

## Phase 6B: Remote HTTP (Primary Production Requirement)

### P6B-01: Decide if remote mode is needed

- [x] ระบุ use cases ที่ local stdio แก้ไม่ได้
- [x] ตัดสินใจว่าจะลงทุน remote mode ตอนนี้หรือไม่
- [x] ถ้ายังไม่ทำ ให้บันทึก decision ไว้ชัดเจน

Depends on: P6A-03

Lane: Product decision

หลักฐาน:
- [mcp-server/REMOTE_MODE_DECISION.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/REMOTE_MODE_DECISION.md)
- [mcp-server/README.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/README.md)

### P6B-02: Design remote-mode constraints

- [x] ออกแบบ auth boundary
- [x] ออกแบบ cache invalidation strategy
- [x] ระบุ freshness model
- [x] ระบุ branch/commit pinning behavior

Depends on: P6B-01

Lane: Architecture

หลักฐาน:
- [mcp-server/REMOTE_MODE_DECISION.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/REMOTE_MODE_DECISION.md)
- [mcp-server/MAINTENANCE_TH.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/MAINTENANCE_TH.md)

หมายเหตุ: เดิม P6B-01/P6B-02 เป็นระดับ decision/design แต่ในสถานะปัจจุบันได้ implement ต่อครบถึง P6B-09 แล้วตาม requirement หลักของ production-ready รุ่นแรก

### P6B-03: Add Streamable HTTP entrypoint

- [x] เพิ่ม HTTP transport entrypoint แยกจาก `index.js` (เช่น `http-server.js`) ที่ reuse `createMcpServer` จาก `app.js`
- [x] เปิด process ผ่าน `npm run start:http` หรือเทียบเท่า โดยไม่กระทบ `npm start` (stdio) เดิม
- [x] ยืนยันว่า tool contracts เดิมทำงานเหมือนกันทั้งสอง transport (ใช้ core logic เดียวกัน ไม่ fork logic)

Depends on: P6B-02

Lane: Remote transport

### P6B-04: Implement auth boundary

- [x] บังคับให้ remote endpoint expose เฉพาะ read-only tools ชุดเดียวกับ local MCP ตามที่ระบุใน `REMOTE_MODE_DECISION.md` ("Auth Boundary")
- [x] ปฏิเสธ repo path ใด ๆ จาก caller — ผูก repo/commit ที่ allowlist ไว้ล่วงหน้าในฝั่ง server เท่านั้น
- [x] ใช้ secret จาก environment variables ผ่าน reverse proxy/deployment edge ตามที่ตัดสินใจไว้ ไม่ทำ auth logic เองใน MCP process
- [x] เพิ่ม rate limiting และ request logging ระดับพื้นฐาน

Depends on: P6B-03

Lane: Remote transport

### P6B-05: Implement commit-scoped cache invalidation

- [x] ผูก index cache กับ `repo identity + commit SHA` ตามที่ระบุใน `REMOTE_MODE_DECISION.md` ("Cache Invalidation Strategy")
- [x] สร้าง cache namespace ใหม่ทุก deployment แทนการ mutate cache เดิมข้าม commit
- [x] implement refresh path (manual หรือ webhook) ที่ invalidate metadata/search index แบบ atomic
- [x] ป้องกันไม่ให้ cache ถูกใช้ข้าม branch/commit โดยไม่ติด label ชัดเจน

Depends on: P6B-03

Lane: Remote transport

### P6B-06: Expose freshness metadata surface

- [x] เพิ่ม health/info surface ที่ client อ่าน `commitSha` และ `deployedAt` ได้ ตามที่ระบุใน `REMOTE_MODE_DECISION.md` ("Freshness Model")
- [x] ประกาศชัดใน docs/metadata ว่า remote mode คือ **snapshot of deployed clone** ไม่ใช่ live working tree
- [x] pin production endpoint กับ immutable commit SHA เสมอ; ถ้ามีหลาย channel (`main`/`staging`) ให้แยก endpoint/server name และไม่แชร์ cache กัน ("Branch / Commit Pinning")

Depends on: P6B-05

Lane: Remote transport

### P6B-07: Zero-clone onboarding docs for remote access

- [x] เขียน onboarding docs ใหม่ (แยกจาก local `stdio` onboarding ใน P6A) ที่ external user config MCP ชี้ hosted endpoint ได้โดยไม่ clone repo
- [x] วัดว่า setup เสร็จได้จริงภายในไม่กี่นาทีบนเครื่องที่ไม่มี repo clone อยู่ก่อน (นี่คือ plan item 9 ที่ P6A ตอบไม่ได้ เพราะ P6A ยัง assume local clone)
- [x] เพิ่มตัวอย่าง config สำหรับ client ที่รองรับ remote MCP URL โดยตรง

Depends on: P6B-04, P6B-06

Lane: Distribution

### P6B-08: Define remote-native client support matrix

- [x] ระบุชัดว่า client ใด verify แล้วว่าใช้ remote/hosted MCP ได้จริง (officially supported) vs client ใดเป็น best-effort/unverified สำหรับ remote mode โดยเฉพาะ (แยกจาก matrix ของ local stdio ใน P6A)
- [x] sync matrix นี้เข้ากับ `mcp-server/COMPATIBILITY_POLICY.md` และ `README.md`

Depends on: P6B-07

Lane: Distribution

### P6B-09: Remote transport tests and CI coverage

- [x] เพิ่ม integration test สำหรับ HTTP entrypoint (เทียบ contract กับ stdio transport ให้ตรงกัน)
- [x] เพิ่ม test สำหรับ auth boundary (reject unauthenticated / reject arbitrary repo path)
- [x] เพิ่ม test สำหรับ cache invalidation ข้าม commit SHA
- [x] ผนวกเข้ากับ CI workflow ที่มีอยู่ (P5-01) ไม่ใช่ pipeline แยก

หลักฐาน Phase 6B:
- [mcp-server/http-server.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/http-server.js)
- [mcp-server/remote_support.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/remote_support.js)
- [mcp-server/scripts/verify-http.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/scripts/verify-http.js)
- [mcp-server/tests/http_server.test.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/tests/http_server.test.js)
- [mcp-server/examples/remote.generic.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/remote.generic.mcp.json)
- [mcp-server/README.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/README.md)
- [mcp-server/COMPATIBILITY_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/COMPATIBILITY_POLICY.md)
- [mcp-server/REMOTE_MODE_DECISION.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/REMOTE_MODE_DECISION.md)

Depends on: P6B-04, P6B-05

Lane: CI

## Phase 7: Operational Readiness

### P7-01: Define versioning and release policy

- [x] กำหนด semantic versioning policy
- [x] กำหนด changelog workflow
- [x] ทำ release checklist

Depends on: P5-01

Lane: Operations

หลักฐาน:
- [mcp-server/RELEASE_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/RELEASE_POLICY.md)
- [mcp-server/CHANGELOG.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/CHANGELOG.md)

### P7-02: Add troubleshooting and maintenance docs

- [x] เพิ่ม troubleshooting guide
- [x] เพิ่ม maintenance guide
- [x] เพิ่ม known failure modes และ recovery steps

Depends on: P4-03, P5-03

Lane: Operations

หลักฐาน:
- [mcp-server/TROUBLESHOOTING.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/TROUBLESHOOTING.md)
- [mcp-server/MAINTENANCE_TH.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/MAINTENANCE_TH.md)

### P7-03: Add basic observability

- [x] structured logs
- [x] timing สำหรับ indexing/search/tool calls
- [x] guideline สำหรับ debug production issues

Depends on: P1-04, P5-01

Lane: Operations

หลักฐาน:
- [mcp-server/observability.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/observability.js)
- [mcp-server/app.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/app.js)
- [mcp-server/widget_catalog.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/widget_catalog.js)
- [mcp-server/tests/observability.test.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/tests/observability.test.js)
- [mcp-server/TROUBLESHOOTING.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/TROUBLESHOOTING.md)

### P7-04: Define compatibility policy

- [x] ระบุ backward compatibility policy ของ tool schema
- [x] ระบุ deprecation process
- [x] ระบุวิธีสื่อสาร breaking changes กับ client users

Depends on: P7-01

Lane: Operations

หลักฐาน:
- [mcp-server/COMPATIBILITY_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/COMPATIBILITY_POLICY.md)
- [mcp-server/RELEASE_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/RELEASE_POLICY.md)

## Parallel Execution Map

### Batch 1: เริ่มได้ทันที

- `P1-01 Normalize tool contracts`
- `P1-03 Improve actionable errors`
- `P1-04 Reduce server coupling`

### Batch 2: หลัง contract เริ่มนิ่ง

- `P1-02 Standardize structured output`
- `P1-05 Freeze tool contract reference`
- `P2-01 Split parser responsibilities`
- `P3-01 Create MCP test harness`

### Batch 3: Parser + Test foundation

- `P2-02 Improve widget discovery rules`
- `P2-03 Improve metadata extraction`
- `P2-05 Improve search ranking`
- `P3-02 Add parser fixtures`

### Batch 4: Verification + CI

- `P3-03 Add unit tests for widget catalog`
- `P3-04 Add integration tests for required tools`
- `P4-01 Script Inspector verification`
- `P5-01 Add MCP CI workflow`

### Batch 5: Distribution + Ops

- `P6A-01 Prepare client config examples`
- `P7-01 Define versioning and release policy`

## Phase 8: Koyeb Hosting Pilot (Multi-Client Remote Access)

เอกสารแผนเต็ม: [mcp-server/KOYEB_HOSTING_PLAN.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/KOYEB_HOSTING_PLAN.md)

เป้าหมาย: ให้ agent จากหลาย client (Claude Code, Codex, Cursor, Antigravity, Kiro) เชื่อม MCP นี้ผ่าน hosted endpoint บน Koyeb ได้โดยไม่ต้อง clone repo โดยไม่แก้โค้ด MCP server ที่มีอยู่

### P8-01: Deploy pilot บน Koyeb

- [ ] ตั้ง Koyeb service ชี้ Work directory `mcp-server`, build `npm ci`, start `node http-server.js`
- [ ] ตั้ง env vars: `MCP_REMOTE_HOST`, `MCP_REMOTE_PORT`, `MCP_REMOTE_PROXY_SHARED_SECRET`, `MCP_REMOTE_REFRESH_TOKEN`, `MCP_REMOTE_CHANNEL`, `MCP_REMOTE_COMMIT_SHA`
- [ ] ตั้ง health check เป็น HTTP path `/health`
- [ ] เปิด auto-deploy จาก push เข้า `main`

วิธีทำ:
- เตรียม GitHub repo นี้ให้อยู่บน branch `main` ล่าสุดก่อน deploy
- ใน Koyeb สร้าง `Web Service` ใหม่จาก GitHub repo นี้ แล้วตั้ง `Work directory = mcp-server`
- ตั้ง `Build command = npm ci`
- ตั้ง `Start command = node http-server.js`
- ตั้ง `Health check path = /health`
- ตั้ง env vars ขั้นต่ำ:
  - `MCP_REMOTE_HOST=0.0.0.0`
  - `MCP_REMOTE_PORT` ใช้ค่าพอร์ตที่ Koyeb inject ให้ หรือ map ตามรูปแบบ deploy ของ Koyeb ถ้า UI รองรับ variable interpolation
  - `MCP_REMOTE_PROXY_SHARED_SECRET` สุ่ม secret ยาวอย่างน้อย 32 ตัวอักษร
  - `MCP_REMOTE_REFRESH_TOKEN` สุ่ม secret แยกอีกตัวสำหรับ `/admin/refresh`
  - `MCP_REMOTE_CHANNEL=production`
  - `MCP_REMOTE_COMMIT_SHA` ใช้ commit ปัจจุบันของ `main` ที่ต้องการ pin
- หลัง deploy เสร็จ ให้เก็บ URL ของ service ไว้ใช้ใน `P8-02`
- หลักฐานที่ควรแนบเมื่อปิดข้อนี้: screenshot หน้า service settings/deploy หรือจดค่าที่ตั้งจริงในโน้ตภายในทีม

ตัวอย่างการหา commit SHA ปัจจุบัน:

```bash
git rev-parse HEAD
```

Depends on: ไม่มี (ใช้ implementation ปัจจุบันของ Phase 6B ตรง ๆ)

Lane: Hosting pilot

### P8-02: Validate held-connection risk

- [ ] รัน `cd mcp-server && npm run verify:mcp:http` ชี้ไปที่ URL ของ Koyeb pilot
- [ ] ยืนยันว่าผ่านครบ: `tools/list`, `list_widgets`, `search_widgets`, `get_widget_metadata`, `/info`, `/admin/refresh`, `/health`
- [ ] บันทึกผลว่า free tier ของ Koyeb (ที่บล็อก held connection จาก internet) กระทบ `StreamableHTTPServerTransport` จริงหรือไม่
- [ ] ถ้า fail: สลับไปประเมิน Northflank เป็น fallback ตาม `KOYEB_HOSTING_PLAN.md` ข้อ 2

วิธีทำ:
- หลังได้ Koyeb URL แล้ว ให้ export env vars สำหรับสคริปต์ verify ตามที่ `mcp-server/scripts/verify-http.js` ใช้งาน
- เรียก verify จากใน `mcp-server/` เพื่อทดสอบ against hosted endpoint แทน localhost
- จดผลลัพธ์แยกเป็น 3 สถานะ: ผ่านครบ, ผ่านบางส่วน, หรือ fail เพราะ connection/streaming
- ถ้า `/health` และ `/info` ผ่าน แต่ MCP calls fail/ค้าง ให้ถือว่า held-connection risk ยังไม่ผ่าน
- ถ้าต้อง fallback ให้เปิด issue/task ย่อยใหม่อ้างอิง Northflank พร้อมแนบ error output จาก Koyeb เป็นหลักฐาน

ตัวอย่างการรัน:

```bash
cd mcp-server
MCP_REMOTE_BASE_URL="https://<your-koyeb-host>/mcp" \
MCP_REMOTE_PROXY_SHARED_SECRET="<same-secret-as-deploy>" \
MCP_REMOTE_REFRESH_TOKEN="<same-refresh-token>" \
npm run verify:mcp:http
```

สิ่งที่ต้องบันทึกเมื่อจบข้อนี้:
- URL ที่ทดสอบ
- commit SHA ที่ deploy
- เวลาที่ทดสอบ
- ผลของ `tools/list`, `list_widgets`, `search_widgets`, `get_widget_metadata`, `/info`, `/admin/refresh`, `/health`
- สรุปชัดว่า Koyeb free tier ใช้ได้หรือไม่สำหรับ `StreamableHTTPServerTransport`

Depends on: P8-01

Lane: Hosting pilot

### P8-03: Domain + TLS

- [ ] ตั้ง Cloudflare CNAME `mcp.yourdomain.com` → Koyeb hostname
- [ ] ผูก custom domain บน Koyeb พร้อม auto TLS
- [ ] พิจารณาเปิด Cloudflare Access/Zero Trust คั่นหน้า subdomain

วิธีทำ:
- เลือก subdomain จริง เช่น `mcp.<yourdomain>.com`
- ใน Cloudflare เพิ่ม `CNAME` ให้ชี้ไปที่ Koyeb hostname ที่ service สร้างให้
- ใน Koyeb เพิ่ม custom domain เดียวกันและรอสถานะ TLS พร้อมใช้งาน
- หลัง DNS propagate แล้ว ทดสอบ `https://<subdomain>/health` และ `https://<subdomain>/info`
- ถ้าต้องการ auth layer เพิ่ม ให้พิจารณา Cloudflare Access แต่ต้องเช็กก่อนว่า flow นี้ยังเข้ากับ `mcp-remote` และ header ที่ระบบคาดไว้

เช็กลิสต์หลังตั้งเสร็จ:
- browser เปิด `/health` ได้
- browser เปิด `/info` ได้
- cert TLS valid
- Koyeb service ยังตอบกลับด้วย domain ใหม่ได้ตรงกับ hostname เดิม

Depends on: P8-02

Lane: Domain/Auth

### P8-04: Multi-client onboarding ด้วย `mcp-remote` bridge

- [ ] เพิ่มไฟล์ตัวอย่าง config `mcp-remote` bridge ใน `mcp-server/examples/`
- [ ] ทดสอบ bridge จริงกับ client อย่างน้อย 1 ตัว (แนะนำ Codex ก่อน)
- [ ] อัปเดต `README.md` / `COMPATIBILITY_POLICY.md` ให้ระบุ `mcp-remote` bridge เป็นทาง recommended สำหรับ multi-client remote access

วิธีทำ:
- เพิ่มไฟล์ตัวอย่าง config ใหม่ใน `mcp-server/examples/` ที่เรียก `npx mcp-remote https://<domain>/mcp`
- ใช้ header auth แบบเดียวกับ hosted endpoint เช่น `Authorization: Bearer <token>` หรือ header ที่ proxy layer ของระบบจริงรองรับ
- เริ่มทดสอบกับ Codex ก่อน เพราะเป็น target ที่ต้องการ path แบบ local stdio bridge ชัดที่สุด
- เมื่อทดสอบผ่าน ให้ sync ตัวอย่างเดียวกันไปยัง docs ของ client อื่น โดยไม่ต้องรับประกัน native remote URL support
- ปรับ `README.md` และ `COMPATIBILITY_POLICY.md` ให้แยกชัดระหว่าง:
  - remote access ผ่าน `mcp-remote` bridge = recommended
  - native remote MCP URL = best-effort / ต้อง verify แยกตาม client

ตัวอย่าง config:

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://mcp.yourdomain.com/mcp",
        "--header",
        "Authorization: Bearer <TOKEN>"
      ]
    }
  }
}
```

หลักฐานที่ควรแนบ:
- ไฟล์ example config ที่เพิ่มจริง
- ผลทดสอบกับ client อย่างน้อย 1 ตัว
- doc diff ใน `README.md` และ `COMPATIBILITY_POLICY.md`

Depends on: P8-03

Lane: Distribution

## Recommended Execution Order

1. ปิด `P1-*`, `P2-*`, `P3-*`, และ `P4-*`
2. ตัดสินใจต่อใน `P6B-*` ว่าต้องลงทุน remote mode หรือไม่
3. ปิด ops/versioning/compatibility ใน `P7-*`
4. ปิด `P6B-*` ครบแล้วตาม requirement หลักของ remote/hosted access และมีหลักฐาน implementation + verification + docs รองรับ
5. ประเมิน `P8-*` เป็นแผนทดลอง hosting บน Koyeb แยกต่างหากจาก production requirement เดิม — ยังไม่ใช่ exit criteria ของ production-ready plan

## Immediate Next Actions

- [x] ปิด `P7-*` ครบทั้ง versioning, troubleshooting, observability, และ compatibility policy
- [x] ยืนยันด้วย `cd mcp-server && npm run check:mcp-syntax`
- [x] ยืนยันด้วย `cd mcp-server && npm test`
- [x] ยืนยันด้วย `cd mcp-server && npm run ci:mcp`
- [x] ยืนยันด้วย `cd mcp-server && npm run validate:onboarding`

---

# Historical Reference: Widget Test Tasks

ส่วนนี้เก็บ backlog เดิมของงาน widget tests ไว้อ้างอิง เนื่องจากมีการใช้งาน `TASKS.md` มาก่อนสำหรับ test backlog ของ Flutter widgets

- งาน shared test harness และ widget test backlog เดิมถูกปิดครบแล้ว
- รายละเอียดเชิงลึกของแผน test เดิมให้อ้างอิง [WIDGET_TEST_PLAN.md](WIDGET_TEST_PLAN.md)
