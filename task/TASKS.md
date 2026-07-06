# MCP Production Tasks

สร้างไฟล์เมื่อ: `2026-07-04 12:54:27 +07`
อัปเดตล่าสุดเมื่อ: `2026-07-06 19:46:20 +0700`

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

## Phase 8: Render Hosting Pilot (Multi-Client Remote Access)

เอกสารแผนเต็ม: [mcp-server/RENDER_HOSTING_PLAN.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/RENDER_HOSTING_PLAN.md)

เป้าหมาย: ให้ agent จากหลาย client (Claude Code, Codex, Cursor, Antigravity, Kiro) เชื่อม MCP นี้ผ่าน hosted endpoint บน Render ได้โดยไม่ต้อง clone repo โดยไม่แก้โค้ด MCP server ที่มีอยู่

หมายเหตุ: Phase 8 นี้เดิมใช้ Koyeb เป็น hosting target แต่ Koyeb ปิด free tier ให้ผู้ใช้ใหม่หลัง Mistral AI เข้าซื้อในต้นปี 2026 จึงเปลี่ยนมาใช้ Render แทน — ดูเหตุผลเต็มใน `RENDER_HOSTING_PLAN.md` ข้อ 2 และ historical reference เดิมที่ [KOYEB_HOSTING_PLAN.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/KOYEB_HOSTING_PLAN.md) (สถานะ Superseded)

### เอกสารที่ต้องอ่านก่อนเริ่ม Phase 8

ก่อนเริ่มงานข้อใดใน P8-01 ถึง P8-04 ให้อ่าน md ตามลำดับนี้ก่อนเสมอ:

1. [AGENTS.md](/Users/Niwat.yah/flutter_widgetbook_3.0/AGENTS.md) — required read order ของ repo บังคับให้อ่านก่อนทุกงาน
2. [MEMORY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/MEMORY.md) — durable knowledge ที่บันทึกไว้แล้วเกี่ยวกับ Render/Phase 8 (เช่น เรื่อง port binding, `render.yaml`)
3. ไฟล์นี้ (`task/TASKS.md`) ส่วน **Phase 8: Render Hosting Pilot** — execution checklist ตัวจริง เช็กว่า P8-01 ถึง P8-04 ข้อไหนทำแล้ว/ยังไม่ทำ
4. [mcp-server/RENDER_HOSTING_PLAN.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/RENDER_HOSTING_PLAN.md) — แผนหลักเต็ม ๆ (เหตุผลเลือก Render, deploy config, ข้อควรระวังเรื่อง port/domain, validation checklist)
5. [mcp-server/REMOTE_MODE_DECISION.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/REMOTE_MODE_DECISION.md) — contract เรื่อง auth boundary, cache invalidation, freshness model, branch/commit pinning ที่แผน Render ต้องยึดตาม
6. [mcp-server/COMPATIBILITY_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/COMPATIBILITY_POLICY.md) — client support matrix (client ไหน officially supported vs best-effort สำหรับ remote mode)
7. [mcp-server/README.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/README.md) — ส่วน Hosted Remote Onboarding และคำสั่ง verify ต่าง ๆ (`verify:mcp:http`, `verify:mcp:remote`)

เอกสารเสริม (ไม่ใช่ execution plan แล้ว แต่มีบริบทประกอบ):

- [mcp-server/KOYEB_HOSTING_PLAN.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/KOYEB_HOSTING_PLAN.md) — สถานะ Superseded เก็บไว้อ้างอิงว่าทำไม provider อื่นถึงถูกตัดออกก่อนหน้านี้

นอกจาก md แล้ว ตาม trust order ของ repo (live source > docs) ควรเปิดดู [render.yaml](/Users/Niwat.yah/flutter_widgetbook_3.0/render.yaml) (Blueprint จริงที่ deploy) และ [mcp-server/http-server.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/http-server.js) คู่กันด้วย เพื่อยืนยันว่า config ที่จะตั้งบน Render ตรงกับโค้ดจริง เช่น ชื่อ env var `MCP_REMOTE_HOST`/`MCP_REMOTE_PORT`

### P8-01: Deploy pilot บน Render

- [x] Apply `render.yaml` Blueprint ที่ repo root (`rootDir: mcp-server`, build `npm ci`, start `node http-server.js`) — ทำผ่าน Render Dashboard โดยผูก GitHub repo `NUX-Design/Wallet_Widgetbook_2.0` กับ branch `main`, service name `flutter-widget-wallet-mcp`, root directory `mcp-server`, build `npm ci`, start `node http-server.js`, plan `free`, region `singapore`
- [x] ตั้ง env vars ที่เป็น secret ใน Render Dashboard (ไม่ commit ลง `render.yaml`): `MCP_REMOTE_PROXY_SHARED_SECRET`, `MCP_REMOTE_REFRESH_TOKEN`, `MCP_REMOTE_COMMIT_SHA`
- [x] ยืนยันว่า health check path `/health` ผ่านหลัง deploy ครั้งแรก
- [x] ยืนยันว่า auto-deploy trigger เฉพาะไฟล์ใต้ `mcp-server/` ตาม `rootDir`

หลักฐานที่ยืนยันการปิด P8-01:
- Render service ที่ถูกสร้างจริงคือ `flutter-widget-wallet-mcp`
- Primary URL: `https://flutter-widget-wallet-mcp.onrender.com`
- Service ID: `srv-d95m7oa8qa3s73e6ahg0`
- Deploy ล่าสุดขึ้น `live` ที่ commit `88bffadb3bd535b6fc4ae7bdfefd63eb8b69949d` บน branch `main`
- `/health` ตอบ `ok: true`, `status: healthy`, `channel: production`, และ `namespace: src::production::88bffadb3bd535b6fc4ae7bdfefd63eb8b69949d`
- `/info` ตอบ `ok: true` พร้อม read-only tool registry 12 tools และ freshness metadata ที่ชี้ commit เดียวกัน

วิธีทำ:
- เตรียม GitHub repo นี้ให้อยู่บน branch `main` ล่าสุดก่อน deploy
- ใน Render สร้าง Blueprint ใหม่จาก GitHub repo นี้ — Render จะ detect `render.yaml` ที่ repo root ให้อัตโนมัติ
- ถ้าใช้ Codex + Render plugin: สั่ง prompt เช่น `"Deploy this project to Render and explain the Blueprint before applying it."` แล้ว review ค่า `rootDir`, `buildCommand`, `startCommand`, `healthCheckPath` ก่อน apply จริง
- หลัง Blueprint sync ครั้งแรก ให้เข้า Dashboard ตั้งค่า secret env vars ที่ `sync: false` ไว้ (`MCP_REMOTE_PROXY_SHARED_SECRET` สุ่มอย่างน้อย 32 ตัวอักษร, `MCP_REMOTE_REFRESH_TOKEN` สุ่มแยกอีกตัว, `MCP_REMOTE_COMMIT_SHA` ใช้ commit ปัจจุบันของ `main`)
- หลัง deploy เสร็จ ให้เก็บ URL ของ service (`https://<service-name>.onrender.com`) ไว้ใช้ใน `P8-02`
- หลักฐานที่ควรแนบเมื่อปิดข้อนี้: screenshot หน้า service settings/deploy หรือจดค่าที่ตั้งจริงในโน้ตภายในทีม

ตัวอย่างการหา commit SHA ปัจจุบัน:

```bash
git rev-parse HEAD
```

Depends on: ไม่มี (ใช้ implementation ปัจจุบันของ Phase 6B ตรง ๆ)

Lane: Hosting pilot

### P8-02: Validate cold-start and transport behavior

- [x] รัน `cd mcp-server && npm run verify:mcp:remote` ชี้ไปที่ URL ของ Render pilot
- [x] ยืนยันว่าผ่านครบ: `tools/list`, `list_widgets`, `search_widgets`, `get_widget_metadata`, `/info`, `/admin/refresh`, `/health`
- [x] วัดเวลา cold start จริงหลัง idle 15+ นาที เทียบกับ "ประมาณ 1 นาที" ที่ Render ประกาศไว้ (`render.com/docs/free`)
- [x] ถ้า fail เพราะ timeout: แยกให้ชัดว่าเป็น cold start ปกติ (retry แล้วผ่าน) หรือเป็นปัญหา transport จริง — ถ้าเป็นปัญหา transport จริงให้พิจารณาอัปเกรด Render paid instance (ไม่ sleep) ก่อนเปลี่ยน provider อีกรอบ ตาม `RENDER_HOSTING_PLAN.md` ข้อ 7-8

วิธีทำ:
- หลังได้ Render URL แล้ว ให้ export env vars สำหรับสคริปต์ verify ตามที่ `mcp-server/scripts/verify-remote.js` ใช้งาน
- ใช้ `mcp-server/scripts/verify-remote.js` สำหรับยิง hosted endpoint จริง; `verify-http.js` ใช้ตรวจ local self-host transport เท่านั้น
- เรียก verify จากใน `mcp-server/` เพื่อทดสอบ against hosted endpoint แทน localhost
- รันครั้งแรกทันทีหลัง idle เพื่อวัด cold start จริง แล้วรันซ้ำทันทีหลังจากนั้นเพื่อยืนยันว่า warm request เร็วปกติ
- จดผลลัพธ์แยกเป็น 3 สถานะ: ผ่านครบ, ผ่านบางส่วน, หรือ fail เพราะ connection/streaming

ตัวอย่างการรัน:

```bash
cd mcp-server
MCP_REMOTE_BASE_URL="https://<your-service>.onrender.com/mcp" \
MCP_REMOTE_PROXY_SHARED_SECRET="<same-secret-as-deploy>" \
MCP_REMOTE_REFRESH_TOKEN="<same-refresh-token>" \
npm run verify:mcp:remote
```

สิ่งที่ต้องบันทึกเมื่อจบข้อนี้:
- URL ที่ทดสอบ
- commit SHA ที่ deploy
- เวลาที่ทดสอบ และเวลา cold start ที่วัดได้จริง
- ผลของ `tools/list`, `list_widgets`, `search_widgets`, `get_widget_metadata`, `/info`, `/admin/refresh`, `/health`
- สรุปชัดว่า Render free tier ใช้ได้จริงหรือไม่สำหรับ use case นี้

ผลที่บันทึกจริง:
- URL ที่ทดสอบ: `https://flutter-widget-wallet-mcp.onrender.com/mcp`
- commit SHA ที่ deploy และยืนยันจาก `/health` + `/info`: `88bffadb3bd535b6fc4ae7bdfefd63eb8b69949d`
- รอบ warm verify ผ่านครบ 8/8 checks ด้วย `npm run verify:mcp:remote`
- รอบ cold-start verify หลังปล่อย idle 15+ นาที ผ่านครบ 8/8 checks ด้วย `time npm run verify:mcp:remote`
- cold-start wall time ที่วัดได้จริง: `26.493s total`
- ผล endpoint/control plane:
  - `/health`: HTTP 200, `ok: true`, `status: healthy`
  - `/info`: HTTP 200, read-only tool registry 12 tools, freshness metadata ตรงกับ commit เดียวกัน
  - `tools/list`: ผ่าน, expose 12 tools
  - `list_widgets`: ผ่าน
  - `search_widgets`: ผ่าน
  - `get_widget_metadata`: ผ่าน (`Buttons`)
  - `/admin/refresh`: HTTP 200
- ข้อสรุป: Render free tier ใช้ได้จริงสำหรับ use case นี้ และรอบ cold start ที่วัดได้จริง (~26.5 วินาที) ยังอยู่ในกรอบที่ยอมรับได้สำหรับ agent-tooling; ยังไม่พบ evidence ของ held-connection restriction หรือปัญหา transport จริงใน hosted `streamable-http` endpoint

Depends on: P8-01

Lane: Hosting pilot

### P8-03: Domain + TLS

- [x] ยืนยันว่า `https://<service-name>.onrender.com/health` และ `/info` ใช้งานได้ทันทีหลัง deploy (Render ให้ TLS ฟรีแบบ auto-renew อยู่แล้วบน free tier ไม่ต้องตั้งค่าเพิ่ม)
- [x] ถ้าต้องการ custom domain: เพิ่ม custom domain ในหน้า service settings บน Render แล้วชี้ DNS (CNAME/ALIAS) จาก domain provider ไปยัง hostname ที่ Render ให้
- [x] พิจารณาเปิด Cloudflare Access/Zero Trust คั่นหน้า custom domain เป็น optional auth layer เพิ่มเติม

วิธีทำ:
- ทดสอบ `https://<service-name>.onrender.com/health` และ `/info` ก่อนว่าตอบกลับถูกต้องด้วย TLS ที่ Render ออกให้เอง
- ถ้าต้องการ custom domain เลือก subdomain จริง เช่น `mcp.<yourdomain>.com` แล้วเพิ่มใน Render service settings → Custom Domains
- เพิ่ม DNS record ตามที่ Render บอก (มักเป็น CNAME) ที่ domain provider แล้วรอ verify + TLS provision เสร็จ
- หลัง DNS propagate แล้ว ทดสอบ `https://<subdomain>/health` และ `https://<subdomain>/info`
- ถ้าต้องการ auth layer เพิ่ม ให้พิจารณา Cloudflare Access แต่ต้องเช็กก่อนว่า flow นี้ยังเข้ากับ `mcp-remote` และ header ที่ระบบคาดไว้

เช็กลิสต์หลังตั้งเสร็จ:
- browser เปิด `/health` ได้
- browser เปิด `/info` ได้
- cert TLS valid
- Render service ยังตอบกลับด้วย domain ใหม่ (ถ้าตั้ง custom domain) ได้ตรงกับ `.onrender.com` hostname เดิม

ผลที่บันทึกจริง:
- ใช้ `.onrender.com` endpoint เดิมต่อ: `https://flutter-widget-wallet-mcp.onrender.com`
- `/health` และ `/info` ผ่านอยู่แล้วจาก `P8-02` จึงยืนยันได้ว่า managed TLS ของ Render ใช้งานได้จริงสำหรับ pilot นี้
- ตัดสินใจ **defer custom domain** เพราะยังไม่มี requirement ด้าน branding/domain ownership เพิ่มเติม และเป้าหมายถัดไปคือ external onboarding ไม่ใช่เปลี่ยน URL
- ตัดสินใจ **defer Cloudflare Access / Zero Trust** เพราะยังไม่ใช่คำตอบหลักของ external MCP onboarding; ปัญหาหลักที่ต้องแก้ต่อคือ trusted-proxy auth flow และ config path ใน `P8-04`
- ข้อสรุป: `P8-03` ปิดได้สำหรับ pilot/internal use โดยใช้ `.onrender.com` + Render managed TLS ต่อไปก่อน

Depends on: P8-02

Lane: Domain/Auth

### P8-04: Multi-client onboarding บน service เดิมด้วย direct bearer auth

- [x] เพิ่มไฟล์ตัวอย่าง config `mcp-remote` bridge ใน `mcp-server/examples/`
- [x] ทดสอบ bridge จริงกับ client อย่างน้อย 1 ตัว (แนะนำ Codex ก่อน)
- [x] อัปเดต `README.md` / `COMPATIBILITY_POLICY.md` ให้ระบุ direct remote URL + `Authorization: Bearer ...` เป็นทางหลัก และ `mcp-remote` bridge เป็น fallback

วิธีทำ:
- เพิ่มไฟล์ตัวอย่าง config ใหม่ใน `mcp-server/examples/` ที่เรียก `npx mcp-remote https://<domain>/mcp`
- ใช้ header auth แบบเดียวกับ hosted endpoint เช่น `Authorization: Bearer <token>`
- ตั้ง `MCP_REMOTE_BEARER_TOKEN` หรือ `MCP_REMOTE_BEARER_TOKENS` บน Render service เดิมเพื่อให้รับ external token ตรง
- เริ่มทดสอบกับ Codex ก่อน เพราะมี Render plugin ติดตั้งอยู่แล้วและเป็น target ที่ต้องการ path แบบ local stdio bridge ชัดที่สุด
- เมื่อทดสอบผ่าน ให้ sync ตัวอย่างเดียวกันไปยัง docs ของ client อื่น โดยไม่ต้องรับประกัน native remote URL support
- ปรับ `README.md` และ `COMPATIBILITY_POLICY.md` ให้แยกชัดระหว่าง:
  - direct remote URL + `Authorization: Bearer ...` = recommended
  - `mcp-remote` bridge = fallback เมื่อ host app มีปัญหากับ native remote URL flow

Step-by-step สำหรับงานจริง:
1. ใช้ Render service เดิม `https://flutter-widget-wallet-mcp.onrender.com/mcp` เป็น public URL หลัก
2. ออกแบบ token model สำหรับ external users
   - อย่างน้อยต้องมี 1 test token สำหรับรอบ verify
   - ห้ามแจก `MCP_REMOTE_PROXY_SHARED_SECRET` ให้ client ภายนอกโดยตรง
3. ตั้ง `MCP_REMOTE_BEARER_TOKEN` หรือ `MCP_REMOTE_BEARER_TOKENS` บน Render Dashboard ของ service เดิม
4. เพิ่ม example config สำหรับ external onboarding ใน `mcp-server/examples/`
   - example แรก: generic remote URL + `Authorization: Bearer <TOKEN>`
   - example ที่สอง: `mcp-remote` bridge ผ่าน `npx mcp-remote https://flutter-widget-wallet-mcp.onrender.com/mcp --header "Authorization: Bearer <TOKEN>"`
5. ทดสอบ transport จากมุมมอง external user
   - ยิงผ่าน public URL ของ Render service เดิม
   - ตรวจอย่างน้อย `tools/list`, `list_widgets`, `search_widgets`, `get_widget_metadata`
6. ทดสอบกับ client อย่างน้อย 1 ตัว
   - target แรกคือ Codex โดยลอง direct remote URL ก่อน
   - ถ้า Codex ผ่าน ให้เก็บผล config/command จริงไว้เป็นหลักฐาน
7. อัปเดต docs
   - `README.md`: hosted onboarding path ใหม่, public URL flow, token/header ที่ user ต้องใส่
   - `COMPATIBILITY_POLICY.md`: แยกชัดว่า direct remote URL เป็น path หลัก และ `mcp-remote` bridge เป็น fallback
8. บันทึกผลและ caveats
   - ระบุว่า public self-serve path พร้อมเมื่อใด
   - ระบุ client ที่ verify แล้ว vs best-effort
   - บันทึกวิธี rotate token และ proxy secret ถ้าเคยใช้ค่าทดสอบหลุดออกนอกระบบ

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

ผลที่บันทึกจริง:
- service จริงที่ใช้ต่อคือ `https://flutter-widget-wallet-mcp.onrender.com/mcp` (service id `srv-d95m7oa8qa3s73e6ahg0`) โดยไม่ต้องเพิ่ม Render service ตัวที่สอง
- ตั้งค่า `MCP_REMOTE_BEARER_TOKENS` บน Render service เดิม และ redeploy จน `/health` กับ `/info` ชี้ commit `9652855e8536d5bbf3b3db4a7b498c683b522130`
- `/info` ยืนยัน `authBoundary.supportsBearerToken: true`
- Codex host-app ทดสอบ MCP ได้จริงแล้วทั้งแบบ bridge/local rehearsal และแบบ production direct URL
- `cd mcp-server && MCP_REMOTE_BASE_URL="https://flutter-widget-wallet-mcp.onrender.com/mcp" MCP_REMOTE_BEARER_TOKEN="<token>" MCP_REMOTE_REFRESH_TOKEN="<refresh-token>" npm run verify:mcp:remote` ผ่านครบ `8/8`

หลักฐานไฟล์:
- [mcp-server/http-server.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/http-server.js)
- [mcp-server/examples/remote.generic.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/remote.generic.mcp.json)
- [mcp-server/examples/mcp-remote.generic.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/mcp-remote.generic.mcp.json)
- [mcp-server/examples/codex-chatgpt-agent.remote-bridge.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/codex-chatgpt-agent.remote-bridge.mcp.json)
- [mcp-server/README.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/README.md)
- [mcp-server/COMPATIBILITY_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/COMPATIBILITY_POLICY.md)

Depends on: P8-03

Lane: Distribution

## Recommended Execution Order

1. ปิด `P1-*`, `P2-*`, `P3-*`, และ `P4-*`
2. ตัดสินใจต่อใน `P6B-*` ว่าต้องลงทุน remote mode หรือไม่
3. ปิด ops/versioning/compatibility ใน `P7-*`
4. ปิด `P6B-*` ครบแล้วตาม requirement หลักของ remote/hosted access และมีหลักฐาน implementation + verification + docs รองรับ
5. ประเมิน `P8-*` เป็นแผนทดลอง hosting บน Render แยกต่างหากจาก production requirement เดิม — ยังไม่ใช่ exit criteria ของ production-ready plan

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
