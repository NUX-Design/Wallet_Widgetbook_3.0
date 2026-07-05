# Production-Ready Plan: `flutter-widget-wallet-mcp`

## Goal

ยกระดับ `mcp-server/` จากสถานะใช้งานได้ภายในทีม ไปสู่ระดับ production-ready สำหรับ use case นี้:

- repo นี้จะถูก push ขึ้น GitHub และถูกใช้งานเป็นแหล่ง widget Flutter กลางของทีม
- Flutter widgets ใน repo นี้จะมีการอัปเดตเข้ามาเรื่อยๆ จากการแปลง design components หรือ design specs จาก Figma มาเป็นโค้ดแล้ว commit/push ขึ้น repo
- ให้ agent จาก **โปรเจกต์ Flutter อื่น** สามารถเรียก MCP นี้ได้
- ให้ agent/IDE clients อื่นสามารถ config MCP นี้เพื่อเข้าถึง GitHub-hosted source of truth นี้ได้โดยตรง แล้วเรียก tools ได้จริงโดยไม่ต้อง clone repo ทั้งก้อนมารันใน local ของตนเอง
- ค้นหา widget ได้ตาม category, ชื่อ, tag, และ keyword
- อ่าน metadata ของ widget ได้ครบ
- ดึง source code ของ base widget และ preview widget ได้ครบ
- sync กับ repo ที่มี widget ใหม่เข้ามาเรื่อยๆ
- มีคุณภาพพอสำหรับใช้งานซ้ำ, onboard ทีม, ลด regression, และรองรับ public onboarding/documentation ได้

## Product Requirements

### Distribution And Usage Model

- source-of-truth ของ widget library คือ GitHub repo นี้
- consumer หลักคือ developers หรือ agents ที่ config MCP เพื่อเข้าถึง repo source-of-truth นี้โดยตรง
- production-ready รุ่นแรกต้องไม่บังคับให้ external users clone repo ทั้งก้อนลงเครื่องเพื่อใช้งาน MCP
- MCP ต้องสะท้อนสถานะของ widget library จาก GitHub-hosted source of truth หรือ deployed snapshot ที่ผูกกับ repo นี้ได้โดยไม่ต้องอาศัย manual local sync
- การ publish repo เป็น public ต้องมาพร้อม flow ติดตั้ง MCP สำหรับ external users ที่ชี้เข้าหา hosted source นี้ได้โดยตรง
- remote/shared MCP access เป็น requirement หลักของ production-ready รุ่นแรก ไม่ใช่ optional enhancement

### Required Tools

- `list_categories()`
- `list_widgets(category?, limit?, offset?)`
- `search_widgets(query, limit?)`
- `get_widget_code(widgetName)`
- `get_widget_preview(widgetName)`
- `get_widget_metadata(widgetName)`

### Required Metadata

- widget name
- category
- props
- dependencies
- internal imports
- preview usage / preview paths
- Figma source link ถ้ามี เพื่อเชื่อมกลับไปยัง design component/spec ต้นทาง
- assets ที่ widget ใช้
- last updated time

### Non-Functional Requirements

- รองรับ repo ที่อัปเดตต่อเนื่อง
- รองรับ flow ที่ widget ใหม่ถูก push เข้ามาเรื่อยๆ จากงานแปลง Figma/design specs -> Flutter code
- ลด false positive / false negative จาก parser
- มี deterministic verification
- มี client config ที่เอาไปใช้ได้จริง
- มี test และ CI ที่กัน regression ได้
- มี onboarding/docs ที่ทำให้ผู้ใช้ภายนอกหรือทีมอื่น config MCP เพื่อเข้าถึง public GitHub-hosted source นี้ได้เองโดยไม่ต้อง clone repo ทั้งก้อน
- ต้องระบุ compatibility scope ของ clients ที่รองรับอย่างเป็นทางการให้ชัด
- ต้องมี freshness model, auth boundary, และ repo/commit targeting ที่ชัดสำหรับ hosted access

## Current Status

### Done

- MCP รวมอยู่ใน `mcp-server/` ตัวเดียวแล้ว
- ตั้งชื่อเป็น `flutter-widget-wallet-mcp`
- มี structured output และ tool annotations แล้ว
- Inspector CLI ใช้งานได้กับ `tools/list` และหลาย `tools/call`
- มี evaluation XML เริ่มต้นแล้ว

### Known Gaps

- parser ยังเป็น heuristic จาก regex / filename / markdown
- ยังไม่มี automated MCP regression tests
- ยังไม่มี CI pipeline สำหรับ MCP โดยเฉพาะ
- ยังไม่มี remote deployment mode
- installer/config ยังเป็นระดับ basic
- ยังไม่มี release process / semantic versioning / changelog flow ที่ชัด

## Production-Ready Definition

จะถือว่า production-ready เมื่อครบทั้งหมด:

1. tools หลักทั้งหมดทำงานผ่าน acceptance tests
2. metadata ที่คืนมามีความแม่นพอและมี fallback ที่ชัด
3. MCP Inspector checks รันได้อัตโนมัติ
4. มี regression tests สำหรับ success + error paths
5. มี CI gate ก่อน merge
6. มี config examples สำหรับ client เป้าหมาย
7. มี ops docs สำหรับ maintain / debug / release
8. มี evaluation suite ที่รันซ้ำได้
9. external user สามารถ config MCP เพื่อเข้าถึง GitHub-hosted source of truth นี้ได้จาก docs ภายในไม่กี่นาที โดยไม่ต้อง clone repo ทั้งก้อน
10. มีการระบุชัดว่า clients ไหน supported officially, clients ไหนเป็น generic/untested compatibility
11. hosted access มี freshness semantics, auth boundary, และ branch/commit targeting ที่ชัดเจนพอสำหรับ production use

## Completion Status

สถานะปัจจุบันของแผนนี้คือ **ปิดครบตาม definition ข้างต้นแล้ว** ใน working tree ปัจจุบัน โดยมี execution checklist อยู่ที่ `task/TASKS.md`

verification ที่ยืนยันซ้ำได้จาก implementation ปัจจุบัน:

- `cd mcp-server && npm run ci:mcp`
- `cd mcp-server && npm run validate:onboarding`

## Delivery Phases

## Phase 1: Stabilize Current MCP

### Objective

ทำให้ implementation ปัจจุบันนิ่งก่อน โดยไม่ขยาย scope transport

### Tasks

- ทำความสะอาด tool contracts ให้สม่ำเสมอทุกตัว
- normalize ชื่อ field input/output ให้คงที่ทั้ง server
- review `list_widgets`, `search_widgets`, `get_widget_metadata` ให้ paging/limits สม่ำเสมอ
- เพิ่ม error messages ที่ actionable
- แยก utility logic ที่กระจัดกระจายให้อยู่ในโมดูลชัดเจน
- ลด coupling ระหว่าง design-system tools กับ widget-library tools เท่าที่ทำได้

### Deliverables

- `mcp-server/index.js` สะอาดขึ้นและมี contract คงที่
- schema ของ tools ถูกนิยามชัดครบทุกตัว
- error cases หลักถูกออกแบบแล้ว

### Acceptance Criteria

- ทุก tool มี input/output shape ชัด
- ทุก tool read-only มี annotations ครบ
- error ที่พบบ่อยบอก next step ได้ เช่น “ใช้ list/search ก่อน”

## Phase 2: Harden Widget Indexing

### Objective

ทำให้การหา widget และ metadata แม่นขึ้นจนใช้งาน production ได้

### Tasks

- แยก parser เป็น 3 ชั้น
  - filesystem discovery
  - Dart parsing
  - markdown/doc enrichment
- ลด reliance กับ filename heuristic อย่างเดียว
- พิจารณาใช้ Dart AST parser หรืออย่างน้อย tree-sitter / analyzer-backed parser
- ปรับ doc matching ให้ map widget-to-doc แม่นขึ้น
- เพิ่ม scoring strategy สำหรับ search
- เพิ่ม stale detection เมื่อ doc กับ code ขัดกัน
- กำหนด precedence rule:
  - code > widget-local docs > schema/docs overview

### Deliverables

- parser module ที่ทดสอบแยกได้
- metadata confidence rules
- documented fallback behavior

### Acceptance Criteria

- widget ที่มี doc หลายไฟล์ใน folder เดียวไม่ปน metadata กัน
- preview mapping แม่นกับทั้ง `preview_*.dart` และ `*_preview.dart`
- props หลักที่มาจาก code ถูกต้องใน sample widgets สำคัญ

## Phase 3: Add Test Coverage

### Objective

สร้าง automated safety net สำหรับ MCP นี้

### Tasks

- เพิ่ม unit tests สำหรับ `widget_catalog.js`
- เพิ่ม fixture-based tests สำหรับ parser edge cases
- เพิ่ม integration tests สำหรับ MCP tool calls
- ทดสอบทั้ง:
  - happy path
  - not found
  - empty preview
  - malformed docs
  - category filter
  - search ranking basics
- เพิ่ม snapshot tests สำหรับ structured outputs ที่ critical

### Deliverables

- `mcp-server/tests/` หรือ equivalent test directory
- test command ใน `mcp-server/package.json`

### Acceptance Criteria

- รัน test ได้ด้วยคำสั่งเดียว
- ครอบ tools หลักทั้งหมด
- regression สำคัญถูกจับได้ก่อน merge

## Phase 4: Inspector + Evaluation Automation

### Objective

เปลี่ยน verification จาก manual เป็น repeatable workflow

### Tasks

- สร้าง script สำหรับ Inspector CLI checks
- verify อย่างน้อย:
  - `tools/list`
  - `list_widgets`
  - `search_widgets`
  - `get_widget_metadata`
  - `get_widget_code`
  - `get_widget_preview`
- เพิ่ม evaluation runner script สำหรับ XML evaluations
- ขยาย evaluation cases ให้ครอบ:
  - category lookup
  - search
  - Figma mapping
  - source extraction
  - preview extraction
  - token lookup

### Deliverables

- script เช่น `npm run verify:mcp`
- evaluation docs + execution guide

### Acceptance Criteria

- verification รันซ้ำได้บนเครื่อง developer และ CI
- evaluation file ถูกจัดเก็บใน repo และอัปเดตได้ตาม version

## Phase 5: CI/CD Gate

### Objective

บังคับคุณภาพก่อน merge

### Tasks

- เพิ่ม CI workflow สำหรับ:
  - syntax check
  - tests
  - Inspector CLI verification
  - evaluation smoke run
- fail build ถ้า schema/tool contract พัง
- กำหนด required checks สำหรับ PR

### Deliverables

- CI config
- contributor instructions

### Acceptance Criteria

- PR ใหม่ที่ทำให้ tool หลักพังต้อง fail อัตโนมัติ
- contributor อ่าน docs แล้วรัน local verify ได้เหมือน CI

## Phase 6: Client Distribution

### Objective

ทำให้ MCP นี้ถูกนำไปใช้จากโปรเจกต์ Flutter อื่นได้ง่าย

### Option A: Local stdio (Maintainer / Debug Mode)

เหมาะกับทีม maintainers หรือ developer ภายในที่ต้อง debug กับ working tree โดยตรง

### Tasks

- ทำ config examples สำหรับ:
  - Claude Code
  - Codex configs
  - Cursor
  - generic MCP JSON template สำหรับ clients ที่ใช้ config shape ใกล้เคียงกัน
- พิจารณาเพิ่ม client-specific templates สำหรับ Kiro, Antigravity, หรือ client อื่นที่ทีมต้องการประกาศรองรับอย่างเป็นทางการ
- รองรับ env/config ที่ระบุ repo root ได้ชัด
- ปรับ installer ให้ generate config ได้หลาย client target
- เขียน maintainer/debug docs สำหรับการใช้ local `stdio` กับ repo working tree
- ระบุ support policy ว่า client ใดผ่านการ verify จริง และ client ใดเป็น best-effort / unverified

### Acceptance Criteria

- developer คนใหม่ setup ได้จาก docs ภายในไม่กี่นาที
- maintainer ภายในสามารถใช้ local `stdio` เพื่อตรวจ debug หรือพัฒนา MCP กับ working tree ล่าสุดได้จริง
- support matrix ของ clients ถูกระบุชัดใน docs และสอดคล้องกับ examples/installer/tests

### Option B: Remote HTTP (Primary Distribution Mode)

เหมาะสำหรับ external users และ agents ที่ต้องเข้าถึง GitHub-hosted source of truth โดยตรงโดยไม่ต้อง clone repo ทุกเครื่อง

### Tasks

- เพิ่ม Streamable HTTP entrypoint
- ออกแบบ auth
- ออกแบบ cache invalidation strategy
- ระบุว่า server ชี้ branch/commit ไหน
- ตัดสินใจเรื่อง freshness:
  - deployed snapshot tied to branch/commit
  - webhook-triggered refresh
  - scheduled rebuild index
- ออกแบบ public onboarding flow สำหรับ clients ที่เชื่อม remote MCP ได้
- กำหนด support matrix ระหว่าง remote-native clients กับ clients ที่ยังต้อง fallback เป็น local/dev flow

### Acceptance Criteria

- external user สามารถเชื่อม MCP เข้ากับ hosted source นี้ได้โดยไม่ต้อง clone repo ทั้งก้อน
- remote mode มี security boundary, freshness model, และ branch/commit targeting ชัด

## Phase 7: Operational Readiness

### Objective

ทำให้ maintain ได้ในระยะยาว

### Tasks

- เพิ่ม changelog / versioning policy
- เพิ่ม troubleshooting guide
- เพิ่ม observability ขั้นพื้นฐาน
  - structured logs
  - timing for indexing/search/tool calls
- ระบุ backward compatibility policy ของ tool schema
- ระบุ deprecation process

### Deliverables

- release checklist
- maintenance guide
- versioning rules

### Acceptance Criteria

- เปลี่ยน tool schema ได้โดยไม่ทำให้ client พังแบบไม่รู้ตัว
- maintainers คนอื่นรับช่วงต่อได้

## Recommended Technical Decisions

### 1. Transport

- **Primary:** remote hosted MCP
- **Reason:** ตรงกับ requirement ล่าสุดว่าผู้ใช้/agents ภายนอกต้อง config เพื่อเข้าถึง GitHub-hosted source of truth นี้ได้โดยตรงโดยไม่ต้อง clone repo ทั้งก้อน
- **Secondary / maintainer mode:** local `stdio`
- **Reason:** ยังมีประโยชน์สำหรับ debug implementation และตรวจ working tree ระหว่างพัฒนา MCP

### 2. Language

- **Primary:** Node.js / JavaScript หรือ TypeScript
- **Reason:** repo มี Node tooling อยู่แล้ว, MCP ecosystem ฝั่ง TypeScript/JS support ดี, Inspector/CLI integration ตรงที่สุด

### 3. Index Strategy

- **Short term:** filesystem scan + short in-memory cache
- **Mid term:** file hash / mtime aware incremental cache
- **Long term:** optional persistent index store ถ้า repo ใหญ่มาก

### 4. Metadata Truth Order

1. Dart source
2. widget-local markdown
3. generated schema / overview docs

## Risks

### Parsing Risk

- regex parsing อาจพังเมื่อ widget structure ซับซ้อนขึ้น
- mitigation: ย้ายไป AST-based parsing ใน Phase 2

### Drift Risk

- docs อาจไม่ตรง code
- mitigation: expose `source` ใน props และเพิ่ม drift checks

### Search Quality Risk

- tags จาก markdown headings อาจ noisy
- mitigation: curate searchable fields และเพิ่ม weighting rules

### Operational Risk

- hosted access อาจมีปัญหา auth/freshness/cache invalidation ถ้าออกแบบไม่ครบ
- mitigation: ทำ branch/commit targeting, webhook-driven refresh, และ explicit freshness contract ตั้งแต่แรก

## Suggested Milestone Order

หมายเหตุ: ลำดับด้านล่างเป็นแผนเชิงประวัติศาสตร์ของการแตกงาน ไม่ใช่สถานะคงค้างปัจจุบัน

1. Phase 1
2. Phase 2
3. Phase 3
4. Phase 4
5. Phase 5
6. Phase 6A
7. Phase 7
8. Phase 6B สำหรับ remote/hosted production requirement

## Suggested Done Checklist

- [x] tool contracts final
- [x] parser hardened
- [x] MCP tests added
- [x] Inspector verification scripted
- [x] evaluation suite complete
- [x] CI enabled
- [x] client config examples complete
- [x] public onboarding docs complete
- [x] supported client matrix documented
- [x] hosted MCP access signed off
- [x] ops/release docs complete
- [x] local stdio mode signed off
- [x] remote mode decision documented

## Immediate Next Actions

ไม่มี outstanding action เชิง production-readiness จากแผนนี้ใน working tree ปัจจุบัน

งานถัดไปควรเป็น maintenance ตามรอบปกติ:

1. รัน `cd mcp-server && npm run ci:mcp` ก่อน merge การเปลี่ยน MCP
2. รัน `cd mcp-server && npm run validate:onboarding` เมื่อแก้ installer/docs/examples
3. อัปเดต `CHANGELOG.md`, compatibility docs, และ examples เมื่อมี schema/client-impacting change
