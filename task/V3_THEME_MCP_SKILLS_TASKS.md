# Theme V3 + MCP + Skills Tasks

สร้างเมื่อ: `2026-07-10 21:49:05 +0700`
อัปเดตล่าสุดเมื่อ: `2026-07-12 01:40:00 +0700`

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
- [x] V3 remote tools เป็น read-only เท่านั้น
- [x] Generated files ถูกสร้างจาก source tokens ไม่แก้ด้วยมือ

Evidence (`2026-07-10 23:47:26 +0700`):

- V3 work อยู่เฉพาะ V3 paths, tests, checklist และ memory; legacy theme/widget/MCP/skills ไม่มี source diff
- `npm run check:v3-boundaries`: PASS — 57 Dart files, 17 changed paths
- `npm run test:v3-boundaries`: PASS — 8/8; ครอบคลุมการ reject legacy theme import และ `ThemeColors.get()` ภายใน Widget V3
- Legacy MCP contract snapshot และ integration tests: PASS — 21/21
- Render architecture ยังใช้ service `flutter-widget-wallet-mcp` และ endpoint `/mcp` เดิม; ไม่มี service/config ชุดที่สอง
- Generated outputs ตรงกับ token sources และ generator รอบสองรายงาน `changedFiles=0`
- `V3 remote tools เป็น read-only เท่านั้น` ยังไม่ติ๊ก เพราะ V3 MCP tools จะถูกสร้างและตรวจจริงใน `V3-14` ถึง `V3-18`

## Exit Criteria

- [x] Theme V3 โหลด primitive 145 tokens และ semantic Light/Dark อย่างละ 55 tokens จาก direct Figma exports
- [x] Light/Dark semantic paths ตรงกันและ alias resolve ได้
- [x] V3 generator deterministic และ validation tests ผ่าน
- [x] Pilot widget V3 มี source, preview, guide และ tests
- [x] Legacy Flutter/MCP baseline ยังผ่าน
- [x] MCP endpoint เดิม expose V3 read-only tools โดย legacy contracts ไม่เปลี่ยน
- [x] Skills V3 พร้อมสำหรับ Codex, Claude Code และ Kiro
- [x] Render `/health`, `/info` และ remote verifier ผ่านบน deployed commit เดียวกัน

Evidence (`2026-07-10 23:47:26 +0700`):

- Theme V3 targeted tests: PASS — counts 145/55/55, mode parity, multi-hop aliases, failure paths, snapshots และ deterministic generation
- `flutter analyze`: PASS — `No issues found`
- `flutter test`: PASS — 139/139
- `npm run check:mcp-syntax`: PASS — 34 files
- `npm test`: PASS — 21/21
- `npm run verify:mcp`: PASS — Inspector stdio workflows
- `npm run verify:mcp:http`: PASS — 12 read-only tools และ hosted workflow
- Widget V3 pilot: PASS — `V3MiniButton` ตรง 12 Figma Size=Mini nodes ด้วย 3 variants × 4 states, icon slots, Light/Dark toggle preview, Widgetbook use case, local guide/metadata และ targeted tests 9/9
- Phase 5 เพิ่ม V3 tools แบบ additive 17 รายการบน dispatcher/HTTP server เดิม; registry ปัจจุบันมี 31 tools รวมและ remote expose 27 read-only tools โดย exclude generation tools เดิม 2 + V3 2; legacy 14 contract definitions ตรง baseline ทุก field และลำดับ
- Skills V3 (`2026-07-11 22:41:00 +0700`): 8 skills ครบ capability parity กับ legacy 8 skills, packaged เป็น 3 native packs (`skills-v3/codex/.codex/skills/`, `skills-v3/claude-code/.claude/skills/`, `skills-v3/kiro/.kiro/skills/`); canonical spec `docs/v3/V3_SKILLS_SPEC.md`; validation evidence `docs/v3/V3_SKILLS_VALIDATION.md`; remote-safe fallbacks ครบ; `npm run validate:v3-skills` PASS 3 packs × 8 skills/17 tools; `npm run check:v3-boundaries -- --base-ref origin/main` PASS 57 Dart files/106 changed paths; `npm run test:v3-boundaries` PASS 6/6; MCP syntax PASS 44 files และ tests PASS 28/28
- Exit Criteria ที่เหลือผูกกับ `V3-22` ถึง `V3-25` (Render rollout) จึงยังไม่ติ๊กก่อนมี deployed evidence จริง
- Render rollout closed (`2026-07-12`): ดู evidence ใน `V3-22` ถึง `V3-25`; deployed commit `5c3f49c1bce1feed7cc32df77d41579a17930fb0` ตรงกับ `origin/main`; `npm run verify:mcp:remote` PASS 8/8 และ `npm run verify:mcp:remote:v3` PASS 13/13 บน endpoint จริง

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
- `scripts/check-v3-boundaries.test.js`: PASS 8/8 allowed/rejected scenarios; checker บล็อก legacy `theme_color.dart` และ `ThemeColors.get()` ทั้งใน Theme V3 และ Widget V3
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

Evidence (`2026-07-11 01:56:32 +0700`):

- Source inputs: `lib/config/themes/v3/tokens/primitive.tokens.json`, `lib/config/themes/v3/tokens/semantic/light.tokens.json`, `lib/config/themes/v3/tokens/semantic/dark.tokens.json`
- `flutter test test/config/themes/v3`: PASS — parser โหลด direct Figma exports ทั้งสามไฟล์และยืนยัน primitive 145, Light 55, Dark 55 พร้อม path parity และ semantic alias chains
- Generator summary ล่าสุด: `Theme V3 generated: primitives=145, light=55, dark=55, changedFiles=0`

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

- [x] สร้าง `docs/v3/V3_WIDGET_CONVENTIONS.md`
- [x] กำหนด folder/file/class naming
- [x] กำหนด preview, test และ local guide requirements
- [x] กำหนด semantic-first และ localization/accessibility rules
- [x] กำหนด metadata section สำหรับ theme version และ tokens

Depends on: V3-06

Lane: Widget architecture

Evidence (`2026-07-11 00:20:19 +0700`): `docs/v3/V3_WIDGET_CONVENTIONS.md` กำหนด V3 path/class naming, semantic-only theme boundary, localization/accessibility, preview/test/local-guide requirements และ YAML metadata contract

### V3-12: Build one pilot V3 widget

- [x] เลือก reusable widget ขนาดเล็กสำหรับ pilot
- [x] เพิ่ม source ใต้ `lib/widgets/v3/<category>/`
- [x] ใช้ `V3ThemeScope.colorsOf(context)` เท่านั้น
- [x] เพิ่ม standalone Light/Dark preview
- [x] เพิ่ม local guide ระบุ V3 tokens
- [x] เพิ่ม targeted widget tests

Depends on: V3-10, V3-11

Lane: Widget pilot

Evidence (`2026-07-11`): `lib/widgets/v3/button/v3_mini_button.dart`, `preview_v3_mini_button.dart`, `V3_MINI_BUTTON_GUIDE.md` และ `test/widgets/v3/button/v3_mini_button_test.dart`; ดึง context/screenshot จาก 12 Figma Size=Mini nodes, รองรับ 3 variants × 4 states × icon slots, standalone preview เริ่ม Light และสลับทั้ง matrix ด้วย Light/Dark toggle, targeted tests PASS 9/9

### V3-13: Validate pilot UX and integration

- [x] ตรวจ Light/Dark visual behavior
- [x] ตรวจ contrast/readability และ interactive states ที่เกี่ยวข้อง
- [x] ตรวจ localization-friendly copy
- [x] ตรวจไม่มี raw/legacy colors ที่ไม่อนุญาต
- [x] ตรวจ Widgetbook/standalone preview usability

Depends on: V3-12

Lane: Widget QA

Evidence (`2026-07-11 02:23:43 +0700`): `docs/v3/V3_WIDGET_PILOT_AUDIT.md`; Figma/Simulator visual comparison PASS, Light/Dark toggle/state token tests PASS, contrast audit PASS, web preview build PASS, Widgetbook registry regenerate PASS, schema regenerate PASS, `flutter analyze` PASS, full `flutter test` PASS 139/139 และ V3 boundary tests PASS 6/6

## Phase 5 — MCP V3 On Existing Server

### V3-14: Implement V3 token catalog

- [x] สร้าง modules ใต้ `mcp-server/v3/`
- [x] อ่านเฉพาะ `lib/config/themes/v3/**`
- [x] รองรับ list/search/get token
- [x] คืน Light/Dark, alias และ Dart usage metadata
- [x] เพิ่ม actionable suggestions เมื่อไม่พบ token

Depends on: V3-10

Lane: MCP V3 tokens

Evidence (`2026-07-11 02:48:23 +0700`): `mcp-server/v3/token_parser.js`, `token_resolver.js`, `token_catalog.js`; fixture/unit tests ใน `mcp-server/tests/v3/token_catalog.test.js` PASS; real catalog อ่าน semantic Light/Dark 55 paths และ `get_v3_color_token(content/primary)` คืน Light `#0F172A`, Dark `#FFFFFF`, aliases `slate/900`/`white` และ `V3ThemeScope.colorsOf(context).contentPrimary`

### V3-15: Implement V3 widget catalog

- [x] index เฉพาะ `lib/widgets/v3/**`
- [x] อ่าน source, preview และ local docs
- [x] ระบุ theme version และ token dependencies
- [x] รองรับ list/search/metadata/code/preview
- [x] เพิ่ม audit check สำหรับ legacy imports และ raw colors

Depends on: V3-12

Lane: MCP V3 widgets

Evidence (`2026-07-11 02:48:23 +0700`): `mcp-server/v3/widget_parser.js`, `widget_catalog.js`, `handlers.js`; isolated fixture ใต้ `mcp-server/tests/fixtures/v3_repo/` มี V3 compliant/broken widgets และ legacy bait; `widget_catalog.test.js`/`tool_integration.test.js` PASS; real `V3MiniButton` metadata/code/preview retrieval และ audit PASS โดยรายงาน `themeVersion=v3` และ semantic dependencies จาก local guide

### V3-16: Define V3 MCP tool contracts

- [x] เพิ่ม contracts สำหรับ `list_v3_color_tokens`
- [x] เพิ่ม contracts สำหรับ `search_v3_color_tokens`
- [x] เพิ่ม contract สำหรับ `get_v3_color_token`
- [x] เพิ่ม V3 widget retrieval contracts
- [x] เพิ่ม `audit_v3_widget`
- [x] ใส่ read-only annotations ครบทุก V3 tool

Depends on: V3-14, V3-15

Lane: MCP contracts

Evidence (`2026-07-11 03:07:08 +0700`): `mcp-server/v3/tool_contracts.js` ประกาศ 17 V3-prefixed contracts: capability parity กับ legacy 14 กลุ่ม พร้อม token list/search และ audit เพิ่มเติม; ทุก contract มี read-only/non-destructive/idempotent/closed-world annotations; `mcp-server/tests/tool_contracts.test.js` และ reviewed `tool_definitions.contracts.json` PASS

### V3-17: Register V3 tools additively

- [x] register V3 handlers โดยไม่แก้ handler เดิม
- [x] รักษา `get_color_token` ให้ใช้ legacy `theme.json`
- [x] ตรวจ tools/list มี legacy + V3 ครบ
- [x] ตรวจ remote registry expose เฉพาะ read-only tools
- [x] ตรวจ generation/write tools ยังถูก exclude

Depends on: V3-16

Lane: MCP integration

Evidence (`2026-07-11 03:07:08 +0700`): additive imports/injection/handler spread ใน `mcp-server/app.js` และ append-only spread ใน `tool_contracts.js`; baseline audit ยืนยัน legacy 14 definitions ไม่เปลี่ยนและ V3 17 definitions ถูก append; tools/list รวม 31 tools, remote registry 27 read-only tools; generation tools เดิม 2 + V3 2 ถูก exclude และ read-only V3 tools อยู่ remote ครบ; legacy `get_color_token(primary/400)` ยังคืน `ThemeColors.get(brightnessKey, 'primary/400')`

### V3-18: Pass MCP regression and V3 verification

- [x] legacy contract tests ผ่าน
- [x] legacy integration/snapshot tests ผ่าน
- [x] V3 parser/catalog/tool tests ผ่าน
- [x] `npm run check:mcp-syntax` ผ่าน
- [x] `npm test` ผ่าน
- [x] `npm run verify:mcp` ผ่าน
- [x] `npm run verify:mcp:http` ผ่าน
- [x] `npm run ci:mcp` ผ่าน

Depends on: V3-17

Lane: MCP verification

Evidence (`2026-07-11 03:07:08 +0700`): `npm run check:mcp-syntax` PASS 44 files; `npm test` PASS 28/28; `npm run verify:mcp` PASS; `npm run verify:mcp:http` PASS พร้อม 27 read-only tools; `npm run ci:mcp` PASS รวม syntax, tests, Inspector stdio, HTTP และ legacy evaluation 7/7; parity tests ยืนยัน V3 paths/prefix/ThemeScope/Figma mapping/generation guardrails และ remote exclusions; snapshot refresh ถูก review ว่าเป็น append-only V3 contracts และ legacy definitions ตรง baseline

## Phase 6 — Skills V3

### V3-19: Create canonical V3 skill specifications

- [x] สร้าง canonical workflow สำหรับ `flutter-widget-v3-beginner`
- [x] สร้าง canonical workflows สำหรับ search/install/adapt/preview
- [x] สร้าง workflows สำหรับ figma-to-code/audit/upgrade
- [x] ยืนยัน capability parity ครบ 8 skills เท่ากับ skills เดิม
- [x] ระบุ MCP server เดิมและ V3 tool routing
- [x] บังคับ V3 path/theme guardrails
- [x] ห้าม migrate widget เดิมอัตโนมัติ

Depends on: V3-16

Lane: Skills design

Evidence (`2026-07-11 22:41:00 +0700`): `docs/v3/V3_SKILLS_SPEC.md` ประกาศ canonical workflow ครบทั้ง 8 skills (`v3-beginner`, `v3-search`, `v3-install`, `v3-adapt`, `v3-preview`, `v3-figma-to-code`, `v3-audit`, `v3-upgrade`) พร้อม 1:1 mapping ต่อ legacy skill เดิม, routing table อ้าง 17 V3 MCP tools จาก `mcp-server/v3/tool_contracts.js`, universal guardrails บังคับ path เฉพาะ `lib/widgets/v3/**`/`test/widgets/v3/**`, ห้าม legacy theme/tool fallback, และห้าม migrate widget เดิมอัตโนมัติ; `v3-beginner` ยังคง mandatory flow `ask → scan → summarize → confirm → execute` เหมือน legacy beginner spec (`mcp-server/FLUTTER_WIDGET_BEGINNER_SKILL_SPEC.md`) แต่ scope เฉพาะ Theme V3 foundation ที่มีอยู่แล้วเท่านั้น

### V3-20: Package V3 skills for supported agents

- [x] สร้าง Codex pack ใต้ `skills-v3/codex/.codex/skills/`
- [x] สร้าง Claude Code pack ใต้ `skills-v3/claude-code/.claude/skills/`
- [x] สร้าง Kiro pack ใต้ `skills-v3/kiro/.kiro/skills/`
- [x] เพิ่ม pack-level README และ installation paths
- [x] ยืนยัน skills เดิมไม่มี diff

Depends on: V3-19

Lane: Skills packaging

Evidence (`2026-07-11 22:41:00 +0700`): Codex pack ที่ `skills-v3/codex/.codex/skills/` มี 8 skill folders แต่ละตัวมี `SKILL.md` + `agents/openai.yaml` (ตรงรูปแบบ legacy `skills/codex/.codex/skills/`); Claude Code pack ที่ `skills-v3/claude-code/.claude/skills/` มี pack-level `README.md` พร้อม 8 skill folders แบบ `SKILL.md` เท่านั้น; Kiro pack มีรูปแบบเดียวกัน; README ทั้งคู่ระบุ remote-safe fallback; `npm run check:v3-boundaries -- --base-ref origin/main` PASS (57 Dart files, 106 changed paths, ไม่มี violation) ยืนยันว่าไม่มีไฟล์ใต้ legacy `skills/**` ถูกแก้ในงานนี้เลย

### V3-21: Validate skill-to-tool workflows

- [x] ทดสอบ v3-beginner ใช้ flow ask → scan → summarize → confirm → execute
- [x] ทดสอบ v3-beginner ไม่แก้ไฟล์ก่อนยืนยันและ route ไป V3 tools เท่านั้น
- [x] ทดสอบ v3-search กับ MCP V3 widget tools
- [x] ทดสอบ v3-adapt/figma-to-code กับ token tools
- [x] ทดสอบ v3-audit ตรวจ legacy import ได้
- [x] ทดสอบ skill ปฏิเสธการแก้ widget เดิมโดยไม่ยืนยัน
- [x] บันทึก prompts และ expected tool sequence
- [x] ยืนยันทั้ง 3 agent packs มี skills V3 ครบ 8 ตัวและ workflow parity ตรงกับ skills เดิม
- [x] ยืนยัน remote-safe fallback สำหรับ workflow ที่ใช้ generation tools
- [x] เพิ่ม repeatable `npm run validate:v3-skills` และ CI gate

Depends on: V3-18, V3-20

Lane: Skills QA

Evidence (`2026-07-11 22:41:00 +0700`): `docs/v3/V3_SKILLS_VALIDATION.md` บันทึก prompts + expected tool sequence สำหรับทั้ง 8 skills และผลจริงจากการเรียก `createToolDispatcher` (`mcp-server/app.js`) ตรงกับ dispatcher ที่ stdio/HTTP ใช้จริง ต่อ pilot widget `V3MiniButton`:
  - `v3-beginner`: `get_v3_design_system_info`/`list_v3_categories` คืนสถานะ Theme V3 foundation จริง (1 widget, category `button`) ยืนยัน flow ask→scan→summarize ทำงานได้ก่อนถาม confirm; SKILL.md ทุก pack ระบุ mandatory flow และห้ามแก้ไฟล์ก่อนยืนยันชัดเจน
  - `v3-search`/`v3-install`: `search_v3_widgets`, `get_v3_widget_metadata`, `get_v3_widget_code`, `get_v3_widget_preview` คืนข้อมูลถูกต้องครบ (props, semanticTokens, source, preview)
  - `v3-adapt`/`v3-figma-to-code`: `get_v3_color_token`, `search_v3_color_tokens`, `get_v3_figma_to_flutter_mapping`, `get_v3_flutter_widget_template`, `get_v3_codebase_patterns` คืนค่า token/mapping/pattern ถูกต้องและตรวจพบ widget เดิมที่ตรงกับ Figma component แล้ว (แนะนำ install แทนสร้างใหม่)
  - `v3-audit`: `audit_v3_widget("V3MiniButton")` คืน `passed: true, findings: []`; legacy-import detection ได้ยืนยันแล้วด้วย broken-widget fixture ใน `mcp-server/tests/v3/widget_catalog.test.js` (V3-15)
  - `v3-upgrade`: `search_v3_widgets("mini")` คืนผลลัพธ์ถูกต้องสำหรับ diff workflow
  - Negative case: `get_v3_widget_metadata("NotARealWidgetXYZ")` คืน error `NOT_FOUND` พร้อม hint โดยไม่ fallback ไป legacy catalog
  - Generation tools: `generate_v3_widget_code`/`generate_v3_widgetbook_use_case` คืน source/instructions เท่านั้นไม่เขียนไฟล์จริง และยืนยันจาก `mcp-server/remote_support.js` ว่าถูก exclude จาก remote registry ทั้งคู่
  - Remote-safe fallback: `v3-beginner`, `v3-preview`, `v3-figma-to-code` ใช้ read-only template/metadata/token/code/preview tools แล้ว author source locally บน Remote MCP; generation tools เป็น optional local/stdio optimization เท่านั้น
  - Repeatable validation: `scripts/validate-v3-skills.js`; `npm run validate:v3-skills` PASS — 3 packs × 8 skills, 17 known V3 tools; Flutter CI รัน command นี้ทุก push/PR
  - Pack parity: 3 packs มี 8 skills ครบเท่ากันทุก pack, mapping 1:1 กับ legacy 8 skills ตาม `docs/v3/V3_SKILLS_SPEC.md`
  - Legacy isolation: `npm run check:v3-boundaries -- --base-ref origin/main` PASS, `npm run test:v3-boundaries` PASS 6/6, `mcp-server` `npm run check:mcp-syntax` PASS 44 files, `npm test` PASS 28/28 (ไม่ได้รับผลกระทบเพราะ Skills V3 ไม่แก้ไฟล์ `mcp-server/**`)

## Phase 7 — Render Rollout

### V3-22: Update Render deploy trigger scope

- [x] คง service `flutter-widget-wallet-mcp` เดิม
- [x] คง rootDir/build/start/health settings เดิม
- [x] เพิ่ม include paths สำหรับ `lib/config/themes/v3/**`
- [x] เพิ่ม include paths สำหรับ `lib/widgets/v3/**`
- [x] ไม่เพิ่ม `skills-v3/**` เป็น runtime deploy trigger
- [x] ตรวจ secrets ยังอยู่เฉพาะ Render Dashboard

Depends on: V3-18

Lane: Render config

Evidence (`2026-07-12 00:55:00 +0700`): `render.yaml` (repo root, checked-in Blueprint SOT) คง `name: flutter-widget-wallet-mcp`, `rootDir: mcp-server`, `buildCommand: npm ci`, `startCommand: node http-server.js`, `healthCheckPath: /health` เดิม; เพิ่ม `buildFilter.paths` = `mcp-server/**`, `lib/config/themes/v3/**`, `lib/widgets/v3/**` เพื่อให้ commit ที่แตะ V3 sources trigger auto-deploy ได้ (ก่อนหน้านี้ไม่มี `buildFilter` เลย); `skills-v3/**` ไม่อยู่ใน paths เพราะ skills ทำงานฝั่ง client; secrets (`MCP_REMOTE_BEARER_TOKENS`, `MCP_REMOTE_PROXY_SHARED_SECRET`, `MCP_REMOTE_REFRESH_TOKEN`, `MCP_REMOTE_COMMIT_SHA`) ยังเป็น `sync: false` ไม่มี literal value ในไฟล์. หมายเหตุ: ต้อง sync Blueprint หรือปรับ Build Filter ใน Render Dashboard ให้ตรงกับ `render.yaml` เพื่อให้มีผลกับ auto-deploy ของ service จริง

### V3-23: Deploy V3 to the existing service

- [x] deploy commit ที่ผ่าน local/CI gates
- [x] ตรวจ build และ start logs
- [x] ตรวจ `/health` ตอบ healthy
- [x] ตรวจ `/info` แสดง V3 tool names
- [x] ตรวจ commit SHA และ namespace ตรงกับ deploy

Depends on: V3-21, V3-22

Lane: Render deployment

Evidence (`2026-07-12 00:55:00 +0700`): deploy commit `5c3f49c1bce1feed7cc32df77d41579a17930fb0` = merge #29 `Merge Theme V3 foundation, MCP V3, and Skills V3` ตรงกับ `git rev-parse origin/main`; build `npm ci` สำเร็จ, runtime `node http-server.js` ทำงาน (user-confirmed + `transport: streamable-http` ใน `/health`); `GET /health` = `status: healthy`, `commitSha=5c3f49c1...`, `widgetCount=23`, `categoryCount=15`, `deployedAt=2026-07-11T17:21:02Z`; `GET /info` = 27 read-only tools รวม V3 tool names ครบ (`get_v3_color_token`, `list_v3_color_tokens`, `search_v3_color_tokens`, `list_v3_widgets`, `search_v3_widgets`, `get_v3_widget_metadata`, `get_v3_widget_code`, `get_v3_widget_preview`, `audit_v3_widget` ฯลฯ); `namespace=src::production::5c3f49c1...` ตรงกับ deploy commit

### V3-24: Run real remote verification

- [x] ใช้ direct remote URL + Bearer auth เดิม
- [x] ตรวจ `tools/list`
- [x] ตรวจ legacy token/widget tools
- [x] ตรวจ V3 token list/search/get
- [x] ตรวจ V3 widget list/search/metadata/code/preview
- [x] ตรวจ unauthenticated request ถูก reject
- [x] ตรวจ write/generation tools ไม่ถูก expose

Depends on: V3-23

Lane: Remote verification

Evidence (`2026-07-12 00:55:00 +0700`): ทดสอบบน endpoint จริง `https://flutter-widget-wallet-mcp.onrender.com/mcp` ด้วย direct `Authorization: Bearer` (secret ไม่บันทึกในไฟล์นี้):
  - `npm run verify:mcp:remote` (legacy): PASS 8/8 — session connect, `tools/list` 27 tools, `list_widgets` (count=2 category=button), `search_widgets` (count=5), `get_widget_metadata` (name=Buttons), `/health`, `/info` (commit `5c3f49c1...`)
  - `npm run verify:mcp:remote:v3` (V3, script ใหม่ `mcp-server/scripts/verify-remote-v3.js`): PASS 13/13 — V3 tools exposed 15/15, generation tools excluded (`generate_widget_code`, `generate_widgetbook_use_case`, `generate_v3_widget_code`, `generate_v3_widgetbook_use_case` ไม่หลุด), `get_v3_color_token(content/primary)` = Light `#0F172A` / Dark `#FFFFFF` / aliases `slate/900`,`white` / usage `V3ThemeScope.colorsOf(context).contentPrimary`, `list_v3_color_tokens` total=55, `search_v3_color_tokens` count=5, `list_v3_widgets` count=1, `search_v3_widgets` count=1, `get_v3_widget_metadata` name=V3MiniButton themeVersion=v3, `get_v3_widget_code` sourceLength=7419, `get_v3_widget_preview` previewFiles=1, `audit_v3_widget` passed=true findings=0
  - Unauthenticated `POST /mcp` (ไม่มี auth header): `HTTP 401` reject

### V3-25: Publish onboarding and close pilot

- [x] สร้าง `docs/v3/V3_REMOTE_MCP_GUIDE.md`
- [x] ระบุว่า URL และ Bearer token mechanism เดิมใช้ได้
- [x] อธิบาย routing ระหว่าง legacy และ V3 tools/skills
- [x] บันทึก verified client paths และ caveats
- [x] ยืนยัน pilot widget ใช้งานผ่าน V3 skill + remote MCP ได้
- [x] อัปเดต `MEMORY.md` ด้วย verified facts หลัง deploy

Depends on: V3-24

Lane: Documentation / rollout

Evidence (`2026-07-12 00:55:00 +0700`): `docs/v3/V3_REMOTE_MCP_GUIDE.md` ระบุ endpoint/URL เดิม, Bearer token mechanism เดิมใช้ได้กับทั้ง legacy + V3, routing table legacy vs 15 V3 tools, Skills V3 remote usage, verified client paths (verify:mcp:remote 8/8, verify:mcp:remote:v3 13/13 บน commit `5c3f49c1...`) และ caveats (free-tier cold start, generation tools local-only, freshness จาก `/health`/`/info`); pilot widget `V3MiniButton` discoverable + ดึง metadata/code/preview ผ่าน V3 tools บน remote endpoint ได้จริง (verifier output); `MEMORY.md` อัปเดต verified Render V3 facts แล้ว

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

- [x] ทุก V3 path/class/tool/skill มี `v3` ชัดเจน
- [x] MCP V3 ไม่ fallback ไป legacy theme
- [x] Legacy contract snapshots เป็น merge gate
- [x] Import-boundary checks ผ่าน
- [x] Rollout เริ่มจาก pilot widget เดียว
- [x] Rollback ใช้ previous Render commit โดยไม่เปลี่ยน URL/secrets

Evidence (`2026-07-12 01:40:00 +0700`): user rollback deploy ของ service `flutter-widget-wallet-mcp` บน Render กลับไป build ก่อนหน้า commit ปัจจุบันจริง; URL (`https://flutter-widget-wallet-mcp.onrender.com/mcp`) และ Bearer secret เดิมยังใช้งานได้ทันทีโดยไม่ต้องหมุน token/endpoint ใหม่ สิ่งเดียวที่ต้องปรับให้ตรงคือ env var `MCP_REMOTE_COMMIT_SHA` ใน Render Dashboard ต้องอัปเดตให้ตรงกับ SHA ของ commit ที่ rollback ไป เพราะ `resolveRemoteCommitSha()` (`mcp-server/remote_support.js:44-49`) อ่านค่านี้ก่อนเสมอถ้ามีการ set ไว้ (ไม่ fallback ไป `git rev-parse HEAD` ของ build จริง); ถ้าไม่ sync ค่านี้ `/health`/`/info` และ `namespace = repoIdentity::channel::commitSha` จะรายงาน commit ผิดจากโค้ดที่รันอยู่จริง แต่ URL/secret ไม่ได้รับผลกระทบ
