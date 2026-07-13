# Widget V3 Local Web Preview Plan

สร้างเมื่อ: `2026-07-14 01:16:46 +0700`

## Goal

แทนที่ Widgetbook ทั้งหมดด้วย Flutter Web preview host ขนาดเล็กที่เปิด Widget V3 ผ่าน local HTML URL ได้จริง โดย MVP ต้องเปิด URL นี้ได้:

```text
http://127.0.0.1:8090/#/button/V3MiniButton
```

ผู้ใช้ preview ไม่ต้องสร้าง Flutter app ใหม่ และ flow นี้ต้องขยายรองรับ Widget V3 จำนวนมากได้โดยไม่กลับไปพึ่ง Widgetbook หรือ Widgetbook Cloud

Execution checklist ของแผนนี้อยู่ที่ [`task/V3_WEB_PREVIEW_TASKS.md`](../task/V3_WEB_PREVIEW_TASKS.md)

## Assumptions And Decisions

- รอบแรกเป็น local-only; ยังไม่ deploy domain หรือ static hosting
- Flutter SDK ใช้เฉพาะฝั่งผู้พัฒนา/agent ที่ build preview bundle ส่วน browser เปิด bundle ที่ build แล้วผ่าน local HTTP server
- `preview_v3_<widget>.dart` ข้าง widget เป็น source of truth สำหรับ sample data, states และ Light/Dark behavior
- MVP เริ่มด้วย explicit registry เพื่อให้เสร็จเร็ว; ตอนนี้ถูกแทนที่ด้วย registry generator แล้ว (VP-10, ดู Phase 7) หลัง local flow ผ่าน verification ครบ
- URL slug ใช้รูปแบบ `<category>/<WidgetClass>` เช่น `button/V3MiniButton`
- Preview host เป็น Flutter Web app เดียว ไม่ build แยก bundle ต่อ widget
- Widgetbook package, annotation, generator, entrypoint, generated registry และ Cloud workflow ต้องถูกถอดออกเมื่อ replacement ผ่าน verification แล้ว
- `build/web/**` เป็น generated output และไม่ commit ลง Git
- Theme V3 และ Widget V3 runtime behavior ต้องไม่เปลี่ยนเพราะการย้าย preview host

## Non-Goals

- Online domain, GitHub Pages, Cloudflare Pages หรือ Render Static Site
- Preview สำหรับ legacy widgets นอก `lib/widgets/v3/**`
- สร้าง catalog UI ขนาดใหญ่ที่เลียนแบบ Widgetbook
- Hot reload ผ่าน browser สำหรับผู้ใช้ที่ไม่มี Flutter SDK
- เปลี่ยน published legacy MCP tool contracts
- เปลี่ยน Theme V3 token sources หรือ generated theme outputs
- Commit Flutter Web build artifacts เข้า repo

## Target Architecture

```text
lib/widgets/v3/<category>/
├── v3_<widget>.dart
└── preview_v3_<widget>.dart     # preview source of truth
                │
                ▼
tool/generate_v3_preview_registry.dart   # scans preview_v3_*.dart, generates registry
                │
                ▼
lib/preview_v3/
├── main.dart                    # Flutter Web entrypoint
├── preview_app.dart              # routing (V3PreviewApp/V3PreviewRoute)
├── preview_definition.dart
├── preview_registry.dart        # hand-maintained validation/lookup API
├── preview_registry.g.dart      # generated entries, do not edit by hand
└── preview_not_found.dart
                │
                ▼
flutter build web -t lib/preview_v3/main.dart
                │
                ▼
build/web/**                     # generated, ignored
                │
                ▼
scripts/serve-v3-preview.sh
                │
                ▼
http://127.0.0.1:8090/#/<category>/<WidgetClass>
                ▲
                │
flutter-widget-v3-preview skill + MCP previewSlug
```

## URL Contract

Canonical local URL:

```text
http://127.0.0.1:8090/#/button/V3MiniButton
```

Rules:

- Fragment path เป็น canonical route เพื่อให้ refresh ทำงานบน static HTTP server โดยไม่ต้องทำ server rewrite
- Root `/` แสดงรายการ preview ขั้นต่ำหรือ redirect ไป pilot widget
- Unknown slug แสดง actionable Not Found พร้อมรายการ slug ที่ใช้ได้
- URL ต้อง share ได้ภายในเครื่องเดียวกันและ reload แล้วอยู่ preview เดิม
- Query parameter เพิ่มภายหลังได้ เช่น `theme=dark`; MVP ยังคงใช้ Light/Dark toggle ภายใน preview

## Phase 1 — Capture Baseline And Freeze Scope

ก่อนเปลี่ยน runtime ให้เก็บ baseline:

```bash
flutter analyze
flutter test
flutter build web --release -t lib/widgets/v3/button/preview_v3_mini_button.dart
```

บันทึก Widgetbook-owned files และ dependencies ก่อนลบ เพื่อป้องกันการลบ source ที่ถูกใช้โดย runtime อื่นโดยไม่ตั้งใจ

Expected result: มีหลักฐานว่า V3MiniButton และ regression suite ผ่านก่อน migration

## Phase 2 — Decouple V3 Preview From Widgetbook

แก้ `lib/widgets/v3/button/preview_v3_mini_button.dart`:

- ลบ `widgetbook_annotation` import
- ลบ `@UseCase` และ use-case builder
- เก็บ `V3MiniButtonPreview`, Light/Dark toggle และ state matrix
- เก็บ standalone `main()` เพื่อ debug entrypoint ได้โดยตรง
- ไม่แก้ public API หรือ semantic token mapping ของ `V3MiniButton`

Expected result: pilot preview compile และรันได้โดยไม่มี Widgetbook import

## Phase 3 — Build The Minimal Preview Host

เพิ่ม:

```text
lib/preview_v3/main.dart
lib/preview_v3/preview_definition.dart
lib/preview_v3/preview_registry.dart
lib/preview_v3/preview_not_found.dart
```

Responsibilities:

- parse `Uri.base.fragment`
- normalize slug
- resolve lazy preview builder จาก registry
- render preview เดียวที่ถูกเลือก
- แสดง Not Found โดยไม่ crash
- ใช้ `MaterialApp` และ responsive shell ขั้นต่ำ
- ไม่ import Widgetbook หรือ legacy theme APIs

MVP registry มี `button/V3MiniButton` เพียงรายการเดียวก่อน

Expected result: `flutter run -d web-server -t lib/preview_v3/main.dart` เปิด pilot route ได้

## Phase 4 — Build And Serve Local HTML

เพิ่ม `scripts/serve-v3-preview.sh` เป็น one-command workflow:

1. ตรวจ Flutter SDK และ project root
2. ตรวจ/เลือก port โดย default `8090`
3. build `lib/preview_v3/main.dart` เมื่อ bundle ไม่มีหรือ source ใหม่กว่า bundle
4. serve `build/web` ผ่าน local HTTP server
5. รอจน `curl` ตรวจ root URL สำเร็จ
6. พิมพ์ exact preview URL หลัง server พร้อมเท่านั้น
7. คง process ไว้จนผู้ใช้หรือ agent หยุด

Default command:

```bash
./scripts/serve-v3-preview.sh
```

Expected output:

```text
V3 preview ready: http://127.0.0.1:8090/#/button/V3MiniButton
```

ห้ามแนะนำให้เปิด `build/web/index.html` ผ่าน `file://` เพราะ Flutter Web assets ต้องถูก serve ผ่าน HTTP

## Phase 5 — Remove Widgetbook Completely

หลัง preview replacement ผ่าน targeted validation แล้วจึงลบ:

```text
lib/widgetbook.dart
lib/widgetbook_use_cases.dart
lib/widgetbook.directories.g.dart
.github/workflows/widgetbook.yml
```

ลบ dependencies ที่ไม่ถูกใช้อีกจาก `pubspec.yaml`:

```yaml
widgetbook
widgetbook_annotation
widgetbook_generator
```

ตรวจ `build_runner` แยกต่างหาก: ลบได้เฉพาะเมื่อไม่มี generator อื่นใช้

อัปเดต docs, scripts และ tests ที่ยังอ้าง Widgetbook โดยไม่ลบ standalone preview conventions

Expected result: `rg -i widgetbook` ไม่พบ runtime/dependency/workflow references เหลือ ยกเว้น migration history ที่ระบุว่าเป็น historical เท่านั้น

## Phase 6 — Integrate MCP And Skills V3

เพิ่มข้อมูลแบบ additive ใน `get_v3_widget_preview`/metadata response:

```json
{
  "widgetName": "V3MiniButton",
  "category": "button",
  "previewSlug": "button/V3MiniButton",
  "localPreviewUrl": "http://127.0.0.1:8090/#/button/V3MiniButton"
}
```

ปรับ `flutter-widget-v3-preview` สำหรับ Codex, Claude Code และ Kiro ให้:

1. resolve widget และ preview slug ผ่าน MCP
2. ตรวจ port ก่อนส่ง URL
3. ถ้า server ยังไม่พร้อม ให้รัน `scripts/serve-v3-preview.sh`
4. รอ HTTP health check ผ่าน
5. เปิด browser หรือส่ง clickable URL
6. ห้ามเรียก Widgetbook use-case generator
7. ห้ามส่ง localhost URL ที่ยังเชื่อมต่อไม่ได้

Published legacy MCP contracts ต้องคงเดิม; response field ใหม่ต้อง additive และมี regression coverage

## Phase 7 — Scale Beyond The Pilot (Implemented)

Registry generator เขียนเสร็จและใช้งานจริงแล้ว (VP-10):

- `tool/v3_preview_registry_generator.dart` — pure discovery/render library: scan `lib/widgets/v3/**/preview_v3_*.dart`, derive `category` จากชื่อโฟลเดอร์ parent, derive widget/preview class name จาก naming convention `preview_v3_<widget>.dart` -> `class V3<Widget>Preview`, ตรวจ duplicate slug และ preview builder หายก่อน generate, sort entries ตาม slug เพื่อ deterministic output
- `tool/generate_v3_preview_registry.dart` — CLI wrapper: `dart run tool/generate_v3_preview_registry.dart` เขียน `lib/preview_v3/preview_registry.g.dart` (รัน `dart format` บน output ให้เสมอ), หรือ `--check` เพื่อ verify ว่า generated output ตรงกับ sources โดยไม่แก้ไฟล์
- `lib/preview_v3/preview_registry.g.dart` เป็น **generated file ห้ามแก้ด้วยมือ**; `lib/preview_v3/preview_registry.dart` (hand-maintained) consume มันผ่าน `generatedV3PreviewEntries` แล้วทำ validation (`ensureUniqueV3PreviewSlugs`) และ public API (`resolve`/`all`) เหมือนเดิม — ไม่กระทบ `preview_app.dart`/`main.dart`
- CI gate: `.github/workflows/widget-sync-ci.yml` มี step "Check Widget V3 preview registry is up to date" รัน `dart run tool/generate_v3_preview_registry.dart --check`; local: `npm run check:v3-preview-registry`
- Generator tests อยู่ที่ `test/tool/v3_preview_registry_generator_test.dart` (8 tests) ครอบคลุม multi-entry scale (พิสูจน์ pipeline ทำงานกับมากกว่า 1 widget), duplicate slug detection, missing builder detection, deterministic rendering, และ empty-list edge case — พิสูจน์ scale flow ผ่าน unit tests แทนการเพิ่ม production widget ตัวที่สองที่ไม่มี Figma source-of-truth จริง (ตัดสินใจร่วมกับผู้ใช้)

ยังไม่ต้องเพิ่ม search/catalog UI จนกว่าจะมี user need จริง; skill เปิด deep link โดยตรงเป็น primary UX (คงเดิม)

## Verification Strategy

Targeted checks:

```bash
dart format lib/preview_v3 lib/widgets/v3/button
flutter analyze
flutter test test/widgets/v3/button/v3_mini_button_test.dart
flutter build web --release -t lib/preview_v3/main.dart
```

Local HTTP checks:

```bash
curl -I http://127.0.0.1:8090/
curl -I http://127.0.0.1:8090/flutter_bootstrap.js
```

Manual browser checks:

- `/#/button/V3MiniButton` แสดง 3 variants × 4 states
- Light/Dark toggle เปลี่ยน semantic palette ถูกต้อง
- refresh แล้วยังอยู่ route เดิม
- viewport แคบไม่ overflow
- unknown route แสดง Not Found
- keyboard focus และ readable contrast ยังใช้งานได้

Regression gates หลังถอด Widgetbook:

```bash
flutter test
npm run check:v3-boundaries
npm run test:v3-boundaries
cd mcp-server && npm run check:mcp-syntax
cd mcp-server && npm test
```

## Acceptance Criteria

- `http://127.0.0.1:8090/#/button/V3MiniButton` เปิดได้จริงหลังรัน command เดียว
- Script ส่ง URL หลัง HTTP server พร้อมเท่านั้น
- Browser แสดง interactive Flutter widget ไม่ใช่ screenshot หรือ HTML approximation
- Pilot preview รองรับ Light/Dark และ state matrix เดิม
- ไม่มี Widgetbook package, annotation, generator, source registry หรือ Cloud workflow เหลือใน active codebase
- `build/web/**` ไม่ถูก commit
- เพิ่ม Widget V3 ใหม่ได้ด้วย preview convention และ registry entry; generator รองรับเมื่อเข้าสู่ scale phase
- Skills V3 ไม่เปิด dead localhost URL และไม่ fallback ไป Widgetbook
- Flutter, V3 boundary และ MCP regression gates ผ่าน

## Main Risk And Mitigation

ความเสี่ยงสูงสุดคือการลบ Widgetbook dependencies ก่อน preview source และ legacy references ถูก decouple ครบ ทำให้ `flutter analyze` หรือ build ทั้ง repo ล้มเหลว

Mitigation:

1. ทำ pilot preview host ให้ compile ผ่านก่อน
2. ตรวจ references ทั้ง repo
3. ลบ Widgetbook source และ dependencies ใน change เดียวกัน
4. รัน `flutter pub get`, analyze และ full tests ทันที
5. rollback เฉพาะ removal หาก replacement ยังไม่ผ่าน โดยไม่แตะ Theme/Widget V3 runtime
