# Skills V3 Validation Evidence

Execution task: `V3-21` ใน [`task/V3_THEME_MCP_SKILLS_TASKS.md`](../../task/V3_THEME_MCP_SKILLS_TASKS.md)

เอกสารนี้บันทึก prompts, expected tool sequence, และหลักฐานการทดสอบ skill-to-tool workflow ของ Skills V3 เดิมทั้ง 8 ตัว เทียบกับ MCP V3 tools จริงบน dispatcher เดิม (`mcp-server/app.js`) โดยใช้ pilot widget `V3MiniButton` เป็น fixture ปัจจุบัน native packs มี skill ที่ 9 คือ `flutter-widget-v3-onboard` ซึ่งเป็น read-only knowledge/router addition และตรวจด้วย validator markers แยกจาก implementation workflows เดิม

## Method

รัน `createToolDispatcher({ projectRoot: <repo root> })` จาก `mcp-server/app.js` ตรงกับ dispatcher เดียวกันที่ `index.js` (stdio) และ `http-server.js` (remote) ใช้จริง แล้วเรียก tool ตามลำดับที่แต่ละ skill's `SKILL.md` ระบุไว้ ต่อ real repo data (ไม่ใช่ fixture) เพื่อยืนยันว่า `SKILL.md` ที่ package ไปแล้วอ้างอิง tool name/argument ถูกต้องและได้ผลลัพธ์ตามที่ canonical spec (`docs/v3/V3_SKILLS_SPEC.md`) อธิบายไว้จริง

Regression validator แบบถาวรอยู่ที่ `scripts/validate-v3-skills.js` และรันด้วย `npm run validate:v3-skills` ทั้ง local และ Flutter CI ตัวตรวจยืนยัน 3 packs × 9 skills, frontmatter/metadata, V3-only tool names เทียบ contract จริง, onboarding read-only/router markers, legacy isolation, beginner flow markers, remote-safe fallback และการ exclude generation tools จาก remote registry

การตรวจเพิ่มสำหรับ onboarding skill (`2026-07-17`): `quick_validate.py` ผ่านครบทั้ง Codex, Claude Code และ Kiro packs หลังติดตั้ง `PyYAML` ใน temporary venv (system Python ไม่มี module นี้) และ `npm run validate:v3-skills` ผ่านที่ 3 packs × 9 skills × 18 known V3 tools

## Per-Skill Prompts And Expected Tool Sequence

### `flutter-widget-v3-beginner`

- ตัวอย่าง prompt: "อยากเริ่มใช้ Theme V3 widget ใหม่ใน repo นี้ ยังไม่รู้ว่าต้องเริ่มยังไง"
- Expected sequence: ask discovery questions → scan `lib/config/themes/v3/generated/` + `lib/widgets/v3/**` → `get_v3_design_system_info` → `list_v3_categories` → summarize → confirm → (ถ้า widget มีอยู่แล้ว) `search_v3_widgets` → `get_v3_widget_metadata` → `get_v3_widget_code` → `get_v3_widget_preview`
- Real evidence: `get_v3_design_system_info({ section: "widgets" })` คืน `{ themeVersion: "v3", count: 1, categories: ["button"] }`; `list_v3_categories` คืน `{ categories: ["button"] }` — ตรงกับ pilot widget เดียวที่มีอยู่จริง ยืนยันว่า flow นี้จะ "summarize what exists" ได้ถูกต้องก่อนถาม confirm
- Explanation-first revalidation (`2026-07-14`): forward-test ด้วย prompt ที่ผู้ใช้ไม่เข้าใจตัวเลือก คืนคำอธิบายภาษาไทยครบสำหรับ Goal, Workspace State, Target Widget และ Change Policy ก่อนถาม, แสดง existing-project scope ทั้ง 3 V3 paths, ยืนยันไม่แตะ legacy และแนะนำชุดปลอดภัย `scan-only, auto-detect, auto, additive-only`; ไม่มีการแก้ไฟล์ก่อน confirm. `quick_validate.py` PASS ทั้ง Codex/Claude Code/Kiro beginner skills และ `npm run validate:v3-skills` PASS 3 packs × 8 skills × 18 known tools.

### `flutter-widget-v3-search`

- ตัวอย่าง prompt: "มี widget V3 อะไรที่เป็นปุ่มบ้าง"
- Expected sequence: `list_v3_categories` → `search_v3_widgets(query="button")` → `get_v3_widget_metadata` กับ top candidate
- Real evidence: `search_v3_widgets({ query: "button" })` คืน 1 ผลลัพธ์ `V3MiniButton` พร้อม `semanticTokens` 14 รายการ; `get_v3_widget_metadata({ widgetName: "V3MiniButton" })` คืน props, docFiles, previewFiles, semanticTokens ครบตามที่ skill ต้องสรุปให้ user

### `flutter-widget-v3-install`

- ตัวอย่าง prompt: "ติดตั้ง V3MiniButton เข้า repo เป้าหมาย"
- Expected sequence: `get_v3_widget_metadata` → `get_v3_widget_code` → `get_v3_widget_preview` → place files → rewire `V3ThemeScope`
- Real evidence: `get_v3_widget_code({ widgetName: "V3MiniButton" })` คืน Dart source เต็มพร้อม import `V3ThemeScope`/`V3ColorPalette`; `get_v3_widget_preview({ widgetName: "V3MiniButton" })` คืน preview source ที่ import `v3_theme_scope.dart` และใช้ Widgetbook `@UseCase` annotation ตรงตาม convention

### `flutter-widget-v3-adapt`

- ตัวอย่าง prompt: "widget V3 ที่ย้ายเข้ามาแล้วใช้สีไม่ตรง repo นี้ ช่วย adapt token ให้หน่อย"
- Expected sequence: read local `V3ThemeScope` → `get_v3_codebase_patterns` → `get_v3_design_system_info` → เมื่อ token ไม่แน่ชัด: `search_v3_color_tokens` / `get_v3_color_token`
- Real evidence: `get_v3_color_token({ tokenName: "content/primary", mode: "both" })` คืน Light `#0F172A` (alias `slate/900`), Dark `#FFFFFF` (alias `white`), `dartUsage: "V3ThemeScope.colorsOf(context).contentPrimary"`; `search_v3_color_tokens({ query: "primary" })` คืน 5 tokens ที่ตรง (`background/primary`, `border/primary`, `button/primary`, `content/primary`, และอีก 1 รายการ) — เพียงพอให้ skill แนะนำ token ที่ถูกต้องแทนการเดา raw hex
- `get_v3_codebase_patterns({ pattern: "theme" })` คืนกฎ "Use V3ThemeScope.colorsOf(context)" และ "never silently fall back to ThemeColors.get()" ตรงกับ guardrail ที่ skill บังคับ

### `flutter-widget-v3-preview`

- ตัวอย่าง prompt: "เปิด local preview ของ V3MiniButton"
- Expected source-repo sequence: ตรวจ `lib/preview_v3/` + `scripts/serve-v3-preview.sh` → ใช้/เขียน `preview_v3_<widget>.dart` → `dart run tool/generate_v3_preview_registry.dart` → `./scripts/serve-v3-preview.sh` → readiness → คืน route; ห้ามเรียก MCP delivery/launcher หรือขอ token
- Expected consumer-repo sequence: เมื่อ source markers ไม่ครบเท่านั้น จึงเรียก `get_v3_widget_preview`/`get_v3_widget_metadata` → signed bundle URL → verified bundle launcher โดยไม่ใช้ launcher token → readiness → คืน route; `UNAUTHORIZED` ต้อง refresh metadata หนึ่งครั้งและห้ามขอ token เพิ่ม
- Claude Code permission regression: launcher asset ต้อง executable และถูกเรียกโดยตรงเป็น standalone Bash tool call พร้อม inline compact `--delivery-json`; ห้าม prefix `node`, temp file, heredoc หรือ compound command เพื่อให้ narrow `Bash(*/flutter-widget-v3-preview/assets/launch-v3-preview.mjs *)` rule match; ใช้ `default` permission mode เพราะ `auto` mode ยังบล็อก remote-bundle execution ได้แม้ rule ตรง
- First-use cold download regression: launcher tool call ต้อง foreground พร้อม `--detach`; launcher รอจน HTTP ready แล้ว detach server/exit หาก host background งานให้ poll task จนได้ `ok:true` ห้ามคืนข้อความ "still waiting"
- Validator บังคับ mode-selection markers, source-first routing, generated-registry guardrail และ secret-handling rule เหมือนกันครบทั้ง Codex, Claude Code และ Kiro packs

### `flutter-widget-v3-figma-to-code`

- ตัวอย่าง prompt: "มี Figma component ชื่อ Mini Button อยากได้ Flutter widget ที่ตรงกัน"
- Expected sequence: `get_v3_figma_to_flutter_mapping` → ถ้าพบ widget เดิมแล้ว ให้เปลี่ยนไปใช้ `flutter-widget-v3-search`/`flutter-widget-v3-install`; ถ้าไม่พบ ใช้ token tools + `get_v3_flutter_widget_template` แล้ว author source locally; local/stdio may optionally call `generate_v3_widget_code`
- Real evidence: `get_v3_figma_to_flutter_mapping({ figmaComponentName: "Mini Button" })` คืน `found: true`, `flutterClass: "V3MiniButton"`, `figmaNodes` ตรงกับ pilot — ยืนยันว่า skill จะ redirect ไป install/search แทนการสร้างใหม่ซ้ำถูกต้อง; สำหรับ component ใหม่ `get_v3_flutter_widget_template` คืน V3-prefixed scaffold ที่ import `V3ThemeScope` และ `generate_v3_widget_code` คืน source/instructions พร้อม `note` โดยไม่เขียนไฟล์

### `flutter-widget-v3-audit`

- ตัวอย่าง prompt: "audit widget V3MiniButton ว่ามี legacy leakage หรือไม่"
- Expected sequence: `audit_v3_widget` → `get_v3_widget_metadata` → `get_v3_design_system_info`/`get_v3_codebase_patterns` → `get_v3_widget_preview`
- Real evidence: `audit_v3_widget({ widgetName: "V3MiniButton" })` คืน `{ passed: true, findings: [] }` สำหรับ pilot widget ที่ผ่านมาตรฐานแล้ว — ยืนยันว่า audit tool ทำงานจริงและจะรายงาน finding ที่ไม่ผ่านเมื่อพบ (ตรวจแล้วใน `mcp-server/tests/v3/widget_catalog.test.js` fixture ที่มี broken widget ใน `V3-15`)

### `flutter-widget-v3-upgrade`

- ตัวอย่าง prompt: "widget V3 ตัวนี้อาจจะเก่าไปแล้ว เทียบกับ MCP ล่าสุดหน่อย"
- Expected sequence: `search_v3_widgets` (ถ้าไม่แน่ใจชื่อ) → `get_v3_widget_metadata` → `get_v3_widget_code` → `get_v3_widget_preview` → diff → selective sync
- Real evidence: `search_v3_widgets({ query: "mini" })` คืน `V3MiniButton` ตัวเดียวตรงตามคาด พร้อมข้อมูลสำหรับ diff ต่อ (จาก `get_v3_widget_metadata`/`get_v3_widget_code` ที่ทดสอบไปแล้วในสองสกิลก่อนหน้า)

## Guardrail Verification

### Reject unconfirmed edits to legacy widgets

- Skill spec (`docs/v3/V3_SKILLS_SPEC.md`) และทุก `SKILL.md` ประกาศ guardrail ชัดเจนว่าห้าม migrate/overwrite widget เดิมนอก `lib/widgets/v3/**` โดยอัตโนมัติ ไม่มี workflow ใดใน 8 skills ที่ระบุ MCP write/generation call ไปยัง legacy path
- `flutter-widget-v3-beginner` คงกฎ mandatory flow `ask → scan → summarize → confirm → execute`; เมื่อเลือก `bootstrap-new` และยืนยัน destination แล้วจึงรัน `flutter create`, ติดตั้ง runtime foundation ผ่าน `get_v3_theme_foundation`, เพิ่ม starter Widget V3/preview/test และตรวจ analyze/test ส่วน mode อื่นยังห้ามสร้าง project โดยปริยาย

### No fallback to legacy tools

- ทุก `SKILL.md` อ้างอิงเฉพาะ tool ที่มี prefix `v3`/`_v3_`; ยืนยันโดยตรวจ `mcp-server/v3/tool_contracts.js` (18 รายการ) ตรงกับชื่อ tool ที่ใช้ในทุก skill ไม่มี tool legacy (`get_widget_metadata`, `get_color_token`, ฯลฯ) ปรากฏใน `SKILL.md` ใดของ `skills-v3/**`
- Negative-path evidence: `get_v3_widget_metadata({ widgetName: "NotARealWidgetXYZ" })` คืน error `NOT_FOUND` พร้อม hint ให้เรียก `list_v3_widgets`/`search_v3_widgets` — ไม่มี fallback ไป legacy widget catalog

### Generation/write tools stay unexposed

- `generate_v3_widget_code` และ `generate_v3_widgetbook_use_case` ถูกเรียกจริงและคืน source/instructions เท่านั้น ไม่มีการเขียนไฟล์จริงบน disk (ยืนยันจาก response shape ที่มีแต่ `code`/`instructions`/`importsToAdd`)
- `mcp-server/remote_support.js` exclude generation tools ทั้ง 4 รายการตามเดิม; `v3-figma-to-code`, `v3-preview` และ `v3-beginner` ใช้ read-only template/metadata/token/code/preview tools บน Remote MCP แล้ว author source ใน target repo เอง ส่วน generation tools เป็น optional local/stdio optimization

### Repeatable validator

- `npm run validate:v3-skills`: PASS — 3 packs, 8 skills ต่อ pack, 18 V3 tool contracts; beginner validator บังคับ markers สำหรับ `flutter create`, foundation manifest, `main.dart`, analyze และ test พร้อม reject ข้อความ `bootstrap-new ... stop here`
- Forward test บน empty temp workspace: `flutter create --project-name v3_starter --org com.wi --platforms web`, ติดตั้ง runtime foundation 11 ไฟล์จาก `V3FoundationCatalog`, เพิ่ม `V3MiniButton`, แล้ว `flutter analyze` PASS และ `flutter test` PASS 1/1
- `.github/workflows/flutter_ci.yml` รัน validator ทุก push/PR ไป `main` และ `dev`
- Validator ยืนยันว่า local-only generation tools ไม่อยู่ใน remote registry และทุก skill ที่อ้าง tool เหล่านี้มี `Remote-Safe Fallback`

## Pack Parity Verification

- ทั้ง 3 agent packs (`skills-v3/codex/.codex/skills/`, `skills-v3/claude-code/.claude/skills/`, `skills-v3/kiro/.kiro/skills/`) มี 8 skill folders ตรงกันทุก pack: `flutter-widget-v3-beginner`, `flutter-widget-v3-search`, `flutter-widget-v3-install`, `flutter-widget-v3-adapt`, `flutter-widget-v3-preview`, `flutter-widget-v3-figma-to-code`, `flutter-widget-v3-audit`, `flutter-widget-v3-upgrade`
- Codex pack: แต่ละ skill มี `SKILL.md` + `agents/openai.yaml` (8/8) ตรงรูปแบบ legacy `skills/codex/.codex/skills/`
- Claude Code pack: แต่ละ skill มี `SKILL.md` เท่านั้น ไม่มี `agents/openai.yaml`, มี pack-level `README.md` ตรงรูปแบบ legacy `skills/claude-code/.claude/skills/`
- Kiro pack: แต่ละ skill มี `SKILL.md` เท่านั้น ไม่มี `agents/openai.yaml`, มี pack-level `README.md` ตรงรูปแบบ legacy `skills/kiro/.kiro/skills/`
- Workflow parity: จำนวน skill (8) และ mapping ต่อ legacy skill ตรงกัน 1:1 (ดูตารางใน `docs/v3/V3_SKILLS_SPEC.md`)

## Legacy Isolation Verification

```bash
npm run check:v3-boundaries -- --base-ref origin/main
npm run test:v3-boundaries
npm run validate:v3-skills
cd mcp-server && npm run check:mcp-syntax
```

- `npm run check:v3-boundaries -- --base-ref origin/main`: PASS — 57 Dart files, 106 changed paths, ไม่มี violation (ยืนยันว่าไม่มีการแก้ไฟล์ใต้ `skills/**` เดิมแม้แต่ไฟล์เดียวระหว่างงาน Skills V3 นี้)
- `npm run test:v3-boundaries`: PASS — 6/6
- `npm run validate:v3-skills`: PASS — 3 packs × 8 skills, 17 known V3 tools
- `cd mcp-server && npm run check:mcp-syntax`: PASS — 44 files (ไม่กระทบเพราะ Skills V3 ไม่แก้ไฟล์ `mcp-server/**`)

## Result

Skills V3 ทั้ง 8 ตัวเรียก MCP V3 tool ที่มีอยู่จริงถูกต้องตามชื่อ/argument shape, ได้ผลลัพธ์ตรงกับ pilot widget `V3MiniButton`, ไม่มี fallback ไป legacy tool และทำงานผ่าน Remote MCP ได้โดยประกอบ source จาก read-only results เมื่อ generation tools ไม่ถูก expose Native packaging ครบทั้ง 3 packs และมี repeatable CI validation ป้องกัน routing/parity/guardrail regression
