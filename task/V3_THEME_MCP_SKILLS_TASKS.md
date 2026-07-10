# Theme V3 + MCP + Skills Tasks

สร้างเมื่อ: `2026-07-10 21:49:05 +0700`
อัปเดตล่าสุดเมื่อ: `2026-07-10 23:47:26 +0700`

Execution checklist นี้แตกจาก [`docs/V3_THEME_MCP_SKILLS_PLAN.md`](../docs/V3_THEME_MCP_SKILLS_PLAN.md) และเป็น source of truth สำหรับติดตามการสร้าง Theme V3, Widget V3, MCP tools V3, Skills V3 และ rollout บน Render service เดิม

## วิธีใช้

- เปลี่ยน checkbox เมื่อมีหลักฐานจริงเท่านั้น
- ทุกครั้งที่แก้ checklist, note หรือ progress ให้ปรับ `อัปเดตล่าสุดเมื่อ`
- แนบหลักฐานเป็น path ของ test, source, preview, docs, command output หรือ deployed metadata
- งานที่แตะ MCP contract ต้องผ่าน legacy regression gate ก่อนปิด
- งานที่แตะ Render ต้องตรวจ `/health`, `/info` และ commit SHA จริง
- ห้ามใส่ Bearer token, proxy secret หรือ refresh token ลงไฟล์นี้

## Global Guardrails

- [x] ไม่แก้ behavior ของ legacy theme files
- [x] ไม่ migrate widget เดิมที่อยู่นอก `lib/widgets/v3/**`
- [x] ไม่เปลี่ยนชื่อ/required args/response types/error semantics ของ legacy MCP tools
- [x] ไม่แก้ skills เดิม; เพิ่มเฉพาะ `skills-v3/**`
- [x] ใช้ Render service และ `/mcp` endpoint เดิม ไม่สร้าง service ตัวที่สอง
- [ ] V3 remote tools เป็น read-only เท่านั้น
- [x] Generated files ถูกสร้างจาก source tokens ไม่แก้ด้วยมือ

Evidence (`2026-07-10 23:47:26 +0700`):

- V3 work อยู่เฉพาะ V3 paths, tests, checklist และ memory; legacy theme/widget/MCP/skills ไม่มี source diff
- `npm run check:v3-boundaries`: PASS — 55 Dart files, 19 changed paths
- `npm run test:v3-boundaries`: PASS — 6/6
- Legacy MCP contract snapshot และ integration tests: PASS — 21/21
- Render architecture ยังใช้ service `flutter-widget-wallet-mcp` และ endpoint `/mcp` เดิม; ไม่มี service/config ชุดที่สอง
- Generated outputs ตรงกับ token sources และ generator รอบสองรายงาน `changedFiles=0`
- `V3 remote tools เป็น read-only เท่านั้น` ยังไม่ติ๊ก เพราะ V3 MCP tools จะถูกสร้างและตรวจจริงใน `V3-14` ถึง `V3-18`

## Exit Criteria

- [x] Theme V3 โหลด primitive 145 tokens และ semantic Light/Dark อย่างละ 55 tokens
- [x] Light/Dark semantic paths ตรงกันและ alias resolve ได้
- [x] V3 generator deterministic และ validation tests ผ่าน
- [ ] Pilot widget V3 มี source, preview, guide และ tests
- [x] Legacy Flutter/MCP baseline ยังผ่าน
- [ ] MCP endpoint เดิม expose V3 read-only tools โดย legacy contracts ไม่เปลี่ยน
- [ ] Skills V3 พร้อมสำหรับ Codex, Claude Code และ Kiro
- [ ] Render `/health`, `/info` และ remote verifier ผ่านบน deployed commit เดียวกัน

Evidence (`2026-07-10 23:47:26 +0700`):

- Theme V3 targeted tests: PASS — 15/15; counts 145/55/55, mode parity, aliases, failure paths, snapshots และ deterministic generation
- `flutter analyze`: PASS — `No issues found`
- `flutter test`: PASS — 128/128
- `npm run check:mcp-syntax`: PASS — 34 files
- `npm test`: PASS — 21/21
- `npm run verify:mcp`: PASS — Inspector stdio workflows
- `npm run verify:mcp:http`: PASS — 12 read-only tools และ hosted workflow
- Exit Criteria ที่เหลือผูกกับ `V3-11` ถึง `V3-25` จึงยังไม่ติ๊กก่อนมี source, tests และ deployed evidence จริง

## Phase 1 — Baseline And Freeze

### V3-01: Capture Flutter baseline

- [x] รัน `flutter analyze`
- [x] รัน `flutter test`
- [x] บันทึกผลและ caveats ของ environment

Depends on: ไม่มี

Lane: Baseline

Evidence (re-verified `2026-07-10 22:59:14 +0700`):

- `flutter analyze`: PASS — `No issues found`
- `flutter test test/support/widget_test_harness_test.dart`: PASS — 6/6; ยืนยัน SVG markup, raster manifest และ Lottie JSON
- `flutter test`: PASS — 114/114
- Environment caveat: test harness ต้อง serve `AssetManifest.bin` ด้วย `StandardMessageCodec`; แก้เฉพาะ test infrastructure โดยไม่เปลี่ยน SVG/Lottie loading branches
- Dependency resolution รายงาน 61 packages ที่มีเวอร์ชันใหม่กว่าแต่ไม่ตรง current constraints; ไม่ได้เปลี่ยน dependency versions

### V3-02: Capture MCP baseline

- [x] รัน `cd mcp-server && npm run check:mcp-syntax`
- [x] รัน `cd mcp-server && npm test`
- [x] รัน `cd mcp-server && npm run verify:mcp`
- [x] รัน `cd mcp-server && npm run verify:mcp:http`
- [x] บันทึก `tools/list`, contract snapshot และจำนวน remote read-only tools เดิม

Depends on: ไม่มี

Lane: Baseline

Evidence:

- `npm run check:mcp-syntax`: PASS — 34 files
- `npm test`: PASS — 21/21; contract snapshot เดิมผ่านโดยไม่ regenerate (`mcp-server/tests/snapshots/tool_definitions.contracts.json`)
- `npm run verify:mcp`: PASS — Inspector `tools/list` และ widget read workflows ผ่าน
- `npm run verify:mcp:http`: PASS — `/info`, refresh, health และ read workflows ผ่าน
- Legacy registry: 14 local tools; remote registry: 12 read-only tools; exclude `generate_widget_code` และ `generate_widgetbook_use_case`
- Environment caveat: ต้องรัน `npm ci` เพื่อติดตั้ง Inspector CLI; `npm audit` รายงาน 3 moderate และ 2 high findings โดยไม่ได้รัน auto-fix

### V3-03: Enforce change boundaries

- [x] เพิ่ม automated check ห้าม `lib/config/themes/v3/**` import legacy `theme_color.dart`
- [x] เพิ่ม automated check ห้าม widget เดิม import V3
- [x] เพิ่ม check ว่า skills เดิมไม่มี diff ในงาน V3
- [x] ระบุ additive-only MCP integration files ใน reviewer checklist

Depends on: V3-01, V3-02

Lane: Guardrails

Evidence:

- `scripts/check-v3-boundaries.js`: scan V3/legacy Dart imports, block `ThemeColors.get()` ใน V3 theme และตรวจ legacy `skills/**` diff เมื่อมี V3 work
- `scripts/check-v3-boundaries.test.js`: PASS 6/6 allowed/rejected scenarios
- `npm run check:v3-boundaries`: PASS — 47 Dart files, 10 changed paths
- `.github/workflows/flutter_ci.yml`: รัน checker/tests ด้วย PR/push base SHA และ full git history
- `docs/v3/V3_REVIEW_CHECKLIST.md`: frozen legacy boundaries, additive-only MCP integration files และ regression gates
- Regression: CI YAML parse PASS; `flutter analyze` PASS; `flutter test` PASS 114/114

## Phase 2 — Theme V3 Foundation

### V3-04: Add token source structure

- [x] สร้าง `lib/config/themes/v3/tokens/primitive.tokens.json`
- [x] สร้าง `lib/config/themes/v3/tokens/semantic/light.tokens.json`
- [x] สร้าง `lib/config/themes/v3/tokens/semantic/dark.tokens.json`
- [x] ตรวจ JSON syntax ทุกไฟล์
- [x] ยืนยัน token counts: primitive 145, Light 55, Dark 55

Depends on: V3-03

Lane: Theme inputs

Evidence (`2026-07-10 23:24:54 +0700`):

- Source inputs: `lib/config/themes/v3/tokens/primitive.tokens.json`, `lib/config/themes/v3/tokens/semantic/light.tokens.json`, `lib/config/themes/v3/tokens/semantic/dark.tokens.json`
- `flutter test test/config/themes/v3`: PASS — parser โหลด JSON ทั้งสามไฟล์และยืนยัน primitive 145, Light 55, Dark 55 พร้อม path parity
- Generator summary: `Theme V3 generated: primitives=145, light=55, dark=55`

### V3-05: Define V3 public model and runtime API

- [x] สร้าง `v3_color_token.dart`
- [x] สร้าง `v3_color_palette.dart`
- [x] สร้าง `v3_theme_scope.dart`
- [x] ใช้ `Theme.of(context).brightness` โดยไม่แก้ ThemeData เดิม
- [x] ตั้งชื่อ public classes ด้วย prefix `V3`

Depends on: V3-04

Lane: Flutter API

Evidence:

- Runtime/model: `lib/config/themes/v3/v3_color_token.dart`, `v3_color_palette.dart`, `v3_theme_scope.dart`
- `test/config/themes/v3/v3_theme_scope_test.dart`: PASS — เลือก `V3ColorPalette.light`/`.dark` จาก `Theme.of(context).brightness`

### V3-06: Document V3 source-of-truth rules

- [x] สร้าง `lib/config/themes/v3/README.md`
- [x] ระบุ editable inputs และ generated outputs
- [x] ระบุ semantic-first usage rule
- [x] ระบุ Light/Dark workflow และ generation command
- [x] ระบุห้ามใช้ legacy theme ภายใน V3

Depends on: V3-04, V3-05

Lane: Theme docs

Evidence: `lib/config/themes/v3/README.md`

## Phase 3 — Generator And Validation

### V3-07: Implement DTCG/Figma token parser

- [x] รองรับ `$type`, `$value.hex`, alpha, components และ colorSpace
- [x] รองรับ `com.figma.aliasData`
- [x] รองรับ alias แบบ `{Core.white}`
- [x] normalize token paths อย่าง deterministic
- [x] คืน error พร้อม token path เมื่อ parse ไม่ได้

Depends on: V3-04

Lane: Generator

Evidence:

- Parser: `lib/config/themes/v3/v3_token_parser.dart`
- `test/config/themes/v3/v3_token_parser_test.dart`: PASS — DTCG values, HEX/alpha/components/colorSpace, Figma aliasData, brace aliases, PascalCase normalization และ actionable malformed input errors

### V3-08: Implement alias resolution and validation

- [x] resolve semantic → primitive aliases
- [x] ตรวจ missing primitive target
- [x] ตรวจ alias cycle
- [x] ตรวจ duplicate normalized paths
- [x] ตรวจ Light/Dark path parity
- [x] ตรวจ Dart property collision

Depends on: V3-07

Lane: Generator

Evidence:

- Resolver: `lib/config/themes/v3/v3_token_resolver.dart`
- `test/config/themes/v3/v3_token_parser_test.dart`: PASS — alias chain, missing target, cycle, duplicate normalized path, mode parity และ Dart property collision failure paths

### V3-09: Generate V3 Dart outputs

- [x] สร้าง `v3_theme_generator.dart`
- [x] generate `v3_primitive_colors.g.dart`
- [x] generate `v3_semantic_colors.g.dart`
- [x] แปลง HEX/alpha เป็น Flutter `Color` ถูกต้อง
- [x] ใช้ primitive constants ใน semantic palette เมื่อ resolve alias ได้
- [x] แสดง token summary หลัง generate

Depends on: V3-05, V3-08

Lane: Generator

Evidence:

- Generator: `lib/config/themes/v3/v3_theme_generator.dart`
- Outputs: `lib/config/themes/v3/generated/v3_primitive_colors.g.dart`, `v3_semantic_colors.g.dart`
- Alpha evidence: generated `V3PrimitiveColors.focus = Color(0x663B82F6)` จาก alpha `0.4`; semantic palettes อ้าง `V3PrimitiveColors.*`
- Command output: `Theme V3 generated: primitives=145, light=55, dark=55, changedFiles=2` ในรอบแรก

### V3-10: Verify deterministic generation

- [x] รัน generator สองครั้งแล้วไม่มี diff รอบสอง
- [x] เพิ่ม golden/snapshot test ของ generated output
- [x] เพิ่ม test สำหรับ malformed token inputs
- [x] รัน targeted V3 theme tests
- [x] รัน `flutter analyze`

Depends on: V3-09

Lane: Theme verification

Evidence (`2026-07-10 23:24:54 +0700`):

- `dart run lib/config/themes/v3/v3_theme_generator.dart` รอบสอง: PASS — `changedFiles=0`
- `flutter test test/config/themes/v3`: PASS — 15/15 รวม checked-in output snapshot และ deterministic second-run tests
- `flutter analyze`: PASS — `No issues found`
- `flutter test`: PASS — 128/128 full regression
- `npm run check:v3-boundaries`: PASS — 55 Dart files, 15 changed paths
- `npm run test:v3-boundaries`: PASS — 6/6

## Phase 4 — Widget V3 Pilot

### V3-11: Define Widget V3 conventions

- [ ] สร้าง `docs/v3/V3_WIDGET_CONVENTIONS.md`
- [ ] กำหนด folder/file/class naming
- [ ] กำหนด preview, test และ local guide requirements
- [ ] กำหนด semantic-first และ localization/accessibility rules
- [ ] กำหนด metadata section สำหรับ theme version และ tokens

Depends on: V3-06

Lane: Widget architecture

Evidence: conventions document

### V3-12: Build one pilot V3 widget

- [ ] เลือก reusable widget ขนาดเล็กสำหรับ pilot
- [ ] เพิ่ม source ใต้ `lib/widgets/v3/<category>/`
- [ ] ใช้ `V3ThemeScope.colorsOf(context)` เท่านั้น
- [ ] เพิ่ม standalone Light/Dark preview
- [ ] เพิ่ม local guide ระบุ V3 tokens
- [ ] เพิ่ม targeted widget tests

Depends on: V3-10, V3-11

Lane: Widget pilot

Evidence: source, preview, guide, tests

### V3-13: Validate pilot UX and integration

- [ ] ตรวจ Light/Dark visual behavior
- [ ] ตรวจ contrast/readability และ interactive states ที่เกี่ยวข้อง
- [ ] ตรวจ localization-friendly copy
- [ ] ตรวจไม่มี raw/legacy colors ที่ไม่อนุญาต
- [ ] ตรวจ Widgetbook/standalone preview usability

Depends on: V3-12

Lane: Widget QA

Evidence: test/preview output และ audit note

## Phase 5 — MCP V3 On Existing Server

### V3-14: Implement V3 token catalog

- [ ] สร้าง modules ใต้ `mcp-server/v3/`
- [ ] อ่านเฉพาะ `lib/config/themes/v3/**`
- [ ] รองรับ list/search/get token
- [ ] คืน Light/Dark, alias และ Dart usage metadata
- [ ] เพิ่ม actionable suggestions เมื่อไม่พบ token

Depends on: V3-10

Lane: MCP V3 tokens

Evidence: modules และ unit tests

### V3-15: Implement V3 widget catalog

- [ ] index เฉพาะ `lib/widgets/v3/**`
- [ ] อ่าน source, preview และ local docs
- [ ] ระบุ theme version และ token dependencies
- [ ] รองรับ list/search/metadata/code/preview
- [ ] เพิ่ม audit check สำหรับ legacy imports และ raw colors

Depends on: V3-12

Lane: MCP V3 widgets

Evidence: modules, fixture และ tests

### V3-16: Define V3 MCP tool contracts

- [ ] เพิ่ม contracts สำหรับ `list_v3_color_tokens`
- [ ] เพิ่ม contracts สำหรับ `search_v3_color_tokens`
- [ ] เพิ่ม contract สำหรับ `get_v3_color_token`
- [ ] เพิ่ม V3 widget retrieval contracts
- [ ] เพิ่ม `audit_v3_widget`
- [ ] ใส่ read-only annotations ครบทุก V3 tool

Depends on: V3-14, V3-15

Lane: MCP contracts

Evidence: contracts และ contract tests

### V3-17: Register V3 tools additively

- [ ] register V3 handlers โดยไม่แก้ handler เดิม
- [ ] รักษา `get_color_token` ให้ใช้ legacy `theme.json`
- [ ] ตรวจ tools/list มี legacy + V3 ครบ
- [ ] ตรวจ remote registry expose เฉพาะ read-only tools
- [ ] ตรวจ generation/write tools ยังถูก exclude

Depends on: V3-16

Lane: MCP integration

Evidence: app/registry diff และ integration tests

### V3-18: Pass MCP regression and V3 verification

- [ ] legacy contract tests ผ่าน
- [ ] legacy integration/snapshot tests ผ่าน
- [ ] V3 parser/catalog/tool tests ผ่าน
- [ ] `npm run check:mcp-syntax` ผ่าน
- [ ] `npm test` ผ่าน
- [ ] `npm run verify:mcp` ผ่าน
- [ ] `npm run verify:mcp:http` ผ่าน
- [ ] `npm run ci:mcp` ผ่าน

Depends on: V3-17

Lane: MCP verification

Evidence: command output และ reviewed snapshots

## Phase 6 — Skills V3

### V3-19: Create canonical V3 skill specifications

- [ ] สร้าง canonical workflows สำหรับ search/install/adapt/preview
- [ ] สร้าง workflows สำหรับ figma-to-code/audit/upgrade
- [ ] ระบุ MCP server เดิมและ V3 tool routing
- [ ] บังคับ V3 path/theme guardrails
- [ ] ห้าม migrate widget เดิมอัตโนมัติ

Depends on: V3-16

Lane: Skills design

Evidence: canonical skill specs

### V3-20: Package V3 skills for supported agents

- [ ] สร้าง Codex pack ใต้ `skills-v3/codex/.codex/skills/`
- [ ] สร้าง Claude Code pack ใต้ `skills-v3/claude-code/.claude/skills/`
- [ ] สร้าง Kiro pack ใต้ `skills-v3/kiro/.kiro/skills/`
- [ ] เพิ่ม pack-level README และ installation paths
- [ ] ยืนยัน skills เดิมไม่มี diff

Depends on: V3-19

Lane: Skills packaging

Evidence: skill packs และ README files

### V3-21: Validate skill-to-tool workflows

- [ ] ทดสอบ v3-search กับ MCP V3 widget tools
- [ ] ทดสอบ v3-adapt/figma-to-code กับ token tools
- [ ] ทดสอบ v3-audit ตรวจ legacy import ได้
- [ ] ทดสอบ skill ปฏิเสธการแก้ widget เดิมโดยไม่ยืนยัน
- [ ] บันทึก prompts และ expected tool sequence

Depends on: V3-18, V3-20

Lane: Skills QA

Evidence: validation notes หรือ automated checks

## Phase 7 — Render Rollout

### V3-22: Update Render deploy trigger scope

- [ ] คง service `flutter-widget-wallet-mcp` เดิม
- [ ] คง rootDir/build/start/health settings เดิม
- [ ] เพิ่ม include paths สำหรับ `lib/config/themes/v3/**`
- [ ] เพิ่ม include paths สำหรับ `lib/widgets/v3/**`
- [ ] ไม่เพิ่ม `skills-v3/**` เป็น runtime deploy trigger
- [ ] ตรวจ secrets ยังอยู่เฉพาะ Render Dashboard

Depends on: V3-18

Lane: Render config

Evidence: Blueprint/Dashboard settings โดยไม่มี secret values

### V3-23: Deploy V3 to the existing service

- [ ] deploy commit ที่ผ่าน local/CI gates
- [ ] ตรวจ build และ start logs
- [ ] ตรวจ `/health` ตอบ healthy
- [ ] ตรวจ `/info` แสดง V3 tool names
- [ ] ตรวจ commit SHA และ namespace ตรงกับ deploy

Depends on: V3-21, V3-22

Lane: Render deployment

Evidence: deploy metadata, `/health`, `/info`

### V3-24: Run real remote verification

- [ ] ใช้ direct remote URL + Bearer auth เดิม
- [ ] ตรวจ `tools/list`
- [ ] ตรวจ legacy token/widget tools
- [ ] ตรวจ V3 token list/search/get
- [ ] ตรวจ V3 widget list/search/metadata/code/preview
- [ ] ตรวจ unauthenticated request ถูก reject
- [ ] ตรวจ write/generation tools ไม่ถูก expose

Depends on: V3-23

Lane: Remote verification

Evidence: remote verifier output โดยไม่บันทึก secrets

### V3-25: Publish onboarding and close pilot

- [ ] สร้าง `docs/v3/V3_REMOTE_MCP_GUIDE.md`
- [ ] ระบุว่า URL และ Bearer token mechanism เดิมใช้ได้
- [ ] อธิบาย routing ระหว่าง legacy และ V3 tools/skills
- [ ] บันทึก verified client paths และ caveats
- [ ] ยืนยัน pilot widget ใช้งานผ่าน V3 skill + remote MCP ได้
- [ ] อัปเดต `MEMORY.md` ด้วย verified facts หลัง deploy

Depends on: V3-24

Lane: Documentation / rollout

Evidence: guide, pilot result และ memory update

## Recommended Execution Order

1. `V3-01` ถึง `V3-03`: freeze baseline และ guardrails
2. `V3-04` ถึง `V3-10`: theme tokens, generator และ validation
3. `V3-11` ถึง `V3-13`: pilot widget
4. `V3-14` ถึง `V3-18`: MCP V3 + regression gates
5. `V3-19` ถึง `V3-21`: Skills V3
6. `V3-22` ถึง `V3-25`: Render rollout และ onboarding

## Main Risk

V3 routing อาจปะปนกับ legacy theme/MCP/skills หรือ additive registry change อาจเปลี่ยน published contract โดยไม่ตั้งใจ

Mitigation checklist:

- [ ] ทุก V3 path/class/tool/skill มี `v3` ชัดเจน
- [ ] MCP V3 ไม่ fallback ไป legacy theme
- [ ] Legacy contract snapshots เป็น merge gate
- [ ] Import-boundary checks ผ่าน
- [ ] Rollout เริ่มจาก pilot widget เดียว
- [ ] Rollback ใช้ previous Render commit โดยไม่เปลี่ยน URL/secrets
