# Skills V3 Canonical Specification

สเปกนี้เป็น canonical source-of-truth สำหรับ Skills V3 ทั้ง 8 ตัว ก่อนแตกไปเป็น native packs ใต้ `skills-v3/codex/`, `skills-v3/claude-code/`, และ `skills-v3/kiro/`

Execution task: `V3-19` ใน [`task/V3_THEME_MCP_SKILLS_TASKS.md`](../../task/V3_THEME_MCP_SKILLS_TASKS.md)

## Scope And Non-Goals

- Skills V3 ใช้ **remote MCP endpoint เดิมเป็นเส้นทางหลัก**: `https://flutter-widget-wallet-mcp.onrender.com/mcp` (หรือ local `stdio` เดิมระหว่างพัฒนา) พร้อม `Authorization: Bearer <TOKEN>` mechanism เดิม — ไม่มี server, URL หรือ secret ชุดใหม่
- Skills V3 เรียกใช้เฉพาะ **V3-prefixed MCP tools** (`*_v3_*`) ที่ประกาศใน `mcp-server/v3/tool_contracts.js`; ห้ามเรียก legacy tool เป็น fallback เมื่อ V3 tool ไม่พบข้อมูล
- Skills V3 อ่าน/เขียนเฉพาะ `lib/widgets/v3/**` (และไฟล์ทดสอบคู่กันใต้ `test/widgets/v3/**`) เป็น target repo scope; ห้าม migrate, overwrite หรือแก้ widget เดิมที่อยู่นอก `lib/widgets/v3/`
- Skills V3 ต้องไม่แก้ theme เดิมใต้ `lib/config/themes/` (นอก `v3/`) และห้ามเรียก `ThemeColors.get()`; สีต้องมาจาก `V3ThemeScope.colorsOf(context)` เท่านั้น
- Skills เดิมใต้ `skills/**` ไม่ถูกแก้โดยงานนี้; Skills V3 เป็น distribution แยกทั้งหมดใต้ `skills-v3/**`

## Capability Parity Requirement

Skills V3 ต้องมี **8 skills** ตรงกับจำนวน skills เดิมทุกตัว โดยแทนที่ tool routing และ path scope ด้วยเวอร์ชัน V3:

| Legacy skill | Skills V3 เทียบเท่า |
|---|---|
| `flutter-widget-beginner` | `flutter-widget-v3-beginner` |
| `flutter-widget-search` | `flutter-widget-v3-search` |
| `flutter-widget-install` | `flutter-widget-v3-install` |
| `flutter-widget-adapt` | `flutter-widget-v3-adapt` |
| `flutter-widget-preview` | `flutter-widget-v3-preview` |
| `flutter-widget-figma-to-code` | `flutter-widget-v3-figma-to-code` |
| `flutter-widget-audit` | `flutter-widget-v3-audit` |
| `flutter-widget-upgrade` | `flutter-widget-v3-upgrade` |

ทุก skill name, path และ tool ที่ Skills V3 เรียกต้องมี `v3` ปรากฏชัดเจน ไม่มี ambiguous naming ที่ทำให้สับสนกับ skill เดิม

## MCP Server And Tool Routing

Server เดิม: `flutter-widget-wallet-mcp`
Endpoint เดิม: `https://flutter-widget-wallet-mcp.onrender.com/mcp`
Auth เดิม: `Authorization: Bearer <TOKEN>`

Available V3 tools (จาก `mcp-server/v3/tool_contracts.js`, 17 รายการ, ทั้งหมด read-only):

```text
get_v3_design_system_info
list_v3_categories
list_v3_color_tokens
search_v3_color_tokens
get_v3_color_token
list_v3_widgets
search_v3_widgets
get_v3_widget_details
get_v3_widget_metadata
get_v3_widget_code
get_v3_widget_preview
audit_v3_widget
get_v3_flutter_widget_template
get_v3_codebase_patterns
get_v3_figma_to_flutter_mapping
generate_v3_widget_code
generate_v3_widgetbook_use_case
```

`generate_v3_widget_code` และ `generate_v3_widgetbook_use_case` คืน source/instructions เท่านั้น (ไม่เขียนไฟล์) และไม่ถูก expose ผ่าน remote registry เช่นเดียวกับ generation tools เดิม จึงเป็นเพียง local/stdio optimization ไม่ใช่ dependency บังคับ เมื่อใช้ Remote MCP ให้ agent ดึง template, metadata, tokens, code และ preview ผ่าน read-only V3 tools แล้วประกอบ source ใน target repo เองโดยยึด conventions และ validation เดิม

### Routing table

| Skill | Primary V3 tools |
|---|---|
| `v3-beginner` | `get_v3_design_system_info`, `get_v3_codebase_patterns`, `list_v3_categories`, `search_v3_widgets`, `get_v3_widget_metadata`, `get_v3_widget_code`, `get_v3_widget_preview`, `get_v3_flutter_widget_template`, `generate_v3_widgetbook_use_case` |
| `v3-search` | `list_v3_categories`, `search_v3_widgets`, `get_v3_widget_metadata` |
| `v3-install` | `get_v3_widget_metadata`, `get_v3_widget_code`, `get_v3_widget_preview` |
| `v3-adapt` | `get_v3_codebase_patterns`, `get_v3_design_system_info`, `get_v3_color_token`, `search_v3_color_tokens`, `get_v3_widget_metadata` |
| `v3-preview` | `get_v3_widget_preview`, `generate_v3_widgetbook_use_case`, `get_v3_widget_metadata` |
| `v3-figma-to-code` | `get_v3_figma_to_flutter_mapping`, `get_v3_flutter_widget_template`, `generate_v3_widget_code`, `list_v3_color_tokens`, `search_v3_color_tokens`, `get_v3_color_token`, `get_v3_design_system_info`, `get_v3_codebase_patterns` |
| `v3-audit` | `audit_v3_widget`, `get_v3_widget_metadata`, `get_v3_design_system_info`, `get_v3_codebase_patterns`, `get_v3_widget_preview` |
| `v3-upgrade` | `get_v3_widget_metadata`, `get_v3_widget_code`, `get_v3_widget_preview`, `search_v3_widgets` |

## Canonical Workflow — `flutter-widget-v3-beginner`

ใช้เมื่อ workspace ยังไม่มี Widget V3 เลย หรือมีบางส่วนแล้วแต่ต้องการเติม widget ใหม่บน Theme V3

ต้องทำงานตาม flow บังคับเดียวกับ `flutter-widget-beginner` เดิม: `ask → scan → summarize → confirm → execute` ห้าม execute ก่อนยืนยัน scope

### Discovery Questions (เหมือน legacy แต่ขอบเขต V3 เท่านั้น)

1. **Goal** — `scan-only` / `bootstrap-existing` / `bootstrap-new`
   - `scan-only`: วิเคราะห์ V3 foundation ที่มีอยู่ (`lib/config/themes/v3/`, `lib/widgets/v3/`) เท่านั้น ไม่แก้ไฟล์
   - `bootstrap-existing`: workspace มี Theme V3 อยู่แล้ว (เช่น repo นี้) ให้เพิ่ม widget V3 ใหม่โดยใช้ foundation เดิม
   - `bootstrap-new`: ถ้ายังไม่มี `lib/config/themes/v3/` เลย ต้องหยุดและแจ้งว่า Theme V3 foundation เป็น prerequisite ที่ต้องทำก่อน (Phase 2-3 ของ `docs/V3_THEME_MCP_SKILLS_PLAN.md`) — skill นี้ไม่สร้าง Theme V3 foundation ใหม่ให้อัตโนมัติ
2. **Workspace State Preference** — `existing-v3-foundation` / `no-v3-foundation-yet` / `auto-detect`
3. **Target Widget Scope** — ชื่อ widget ที่จะเพิ่ม หรือ `auto` ให้ skill เลือกจาก MCP catalog (`search_v3_widgets`/`list_v3_widgets`) โดย priority คือ widget ที่ยังไม่มีใน `lib/widgets/v3/**` ของ target repo
4. **Change Policy** — `additive-only` / `allow-structure-setup` / `ask-before-overwrite` (ความหมายเหมือน legacy แต่ scope เฉพาะ `lib/widgets/v3/**` และ `test/widgets/v3/**`)

### Scan

ตรวจอย่างน้อย:

- มี `lib/config/themes/v3/generated/` (แปลว่า Theme V3 foundation พร้อมใช้) หรือไม่
- มี `lib/widgets/v3/**` อยู่แล้วกี่ widget และมี pattern อะไรบ้าง
- มี `test/widgets/v3/**` และ preview `preview_v3_*.dart` คู่กันหรือไม่
- widget เป้าหมายมีอยู่แล้วหรือยัง (ถ้ามีแล้วให้เปลี่ยนไปใช้ `flutter-widget-v3-upgrade` หรือ `flutter-widget-v3-adapt` แทน)

### Summary + Confirm

สรุปก่อน execute เสมอ: พบ Theme V3 foundation หรือไม่, มี widget V3 อะไรอยู่แล้ว, จะเพิ่ม/แก้ไฟล์อะไร, มี risk อะไร (เช่น ยังไม่มี Theme V3 foundation) จากนั้นถาม `proceed` / `revise-scope` / `stop-after-scan`

### Execute

ใช้ `get_v3_widget_metadata` + `get_v3_widget_code` + `get_v3_widget_preview` ถ้า widget ที่ต้องการมีอยู่ใน MCP catalog แล้ว หากต้อง scaffold widget ใหม่ ให้ใช้ `get_v3_flutter_widget_template`; local/stdio อาจใช้ `generate_v3_widgetbook_use_case` เพิ่มเติม ส่วน Remote MCP ให้ agent เขียน preview/use case เองจาก read-only results ตาม `docs/v3/V3_WIDGET_CONVENTIONS.md`

## Canonical Workflow — `flutter-widget-v3-search`

1. Restate use case เป็น search terms
2. `list_v3_categories` ก่อนถ้า request กว้าง
3. `search_v3_widgets` ด้วย intent words
4. `get_v3_widget_metadata` กับ candidate อันดับต้น ๆ
5. สรุป 1-3 ตัวเลือกพร้อม theme version (`v3`), semantic token dependencies, และ preview availability

Guardrail: ถ้าไม่พบ widget V3 ที่ตรง ให้แนะนำ `flutter-widget-v3-figma-to-code` หรือ `flutter-widget-v3-beginner` แทนที่จะเสนอ widget เดิม (legacy) ให้ migrate ถ้า request จริง ๆ คือ "อยากดู component นี้รันจริง" ให้ระบุชื่อ widget ให้ชัดในสกิลนี้ก่อน แล้ว hand off ไป `flutter-widget-v3-preview` (Live Browser Preview) เพื่อรัน ไม่ใช่พยายามรันเองจากสกิลนี้

## Canonical Workflow — `flutter-widget-v3-install`

1. ยืนยันชื่อ widget V3 หรือใช้ `flutter-widget-v3-search` เพื่อหาก่อน
2. `get_v3_widget_metadata` เพื่อดู source path, preview path, local guide, theme version, semantic tokens
3. `get_v3_widget_code` ดึง Dart source
4. `get_v3_widget_preview` ดึง standalone preview
5. วางไฟล์ตาม `lib/widgets/v3/<category>/` และ `test/widgets/v3/<category>/` convention ใน target repo
6. ปรับ import ให้ใช้ `V3ThemeScope.colorsOf(context)` ของ target repo เท่านั้น — ห้าม fallback ไป legacy theme ของ target repo แม้ target repo จะไม่มี Theme V3 (ในกรณีนั้นต้องหยุดและแนะนำให้รัน `flutter-widget-v3-beginner` ก่อน)

## Canonical Workflow — `flutter-widget-v3-adapt`

1. อ่าน local `V3ThemeScope` / semantic token ของ target repo ก่อน
2. `get_v3_codebase_patterns` และ `get_v3_design_system_info` เพื่อดู V3 conventions ต้นทาง
3. ถ้า token ไม่แน่ชัดใน target repo ให้เรียก `search_v3_color_tokens` หรือ `get_v3_color_token`
4. Normalize imports, token usage, naming ให้ตรง `V3_WIDGET_CONVENTIONS.md`
5. ห้าม wrap หรือ fallback กลับไปใช้ token/theme เดิม (`ThemeColors.get()`) ไม่ว่ากรณีใด

## Canonical Workflow — `flutter-widget-v3-preview`

1. ตรวจว่า target repo ใช้ standalone preview (`preview_v3_*.dart`) หรือ Widgetbook
2. `get_v3_widget_preview` ดึงตัวอย่าง preview จาก MCP
3. ถ้าต้อง Widgetbook use case ใหม่ ให้ local/stdio ใช้ `generate_v3_widgetbook_use_case` ได้แบบ optional; Remote MCP ให้เขียน use case เองจาก preview/metadata และ conventions
4. คง Light/Dark toggle coverage เหมือน pilot `V3MiniButton`
5. ห้ามแก้ `lib/widgetbook.directories.g.dart` ด้วยมือ

### Live Browser Preview (ตามคำขอ)

เมื่อผู้ใช้ระบุชื่อ component และต้องการ "เห็นมันรันจริง" ไม่ใช่แค่อ่าน source:

1. หา preview entrypoint: ถ้ามีอยู่แล้วใช้ `lib/widgets/v3/<category>/preview_v3_<widget>.dart` ที่มีอยู่; ถ้ายังไม่มีให้ทำ `flutter-widget-v3-install` ก่อนเพื่อให้มีไฟล์ preview จริงก่อนรัน — ห้ามเดา path เอง
2. เลือก local port ที่ยังไม่ถูกใช้ (แนะนำ `8090` เป็นค่าเริ่มต้น เพิ่มทีละ 1 ถ้าชนกับ preview อื่นที่รันอยู่)
3. รันเป็น background process โดยไม่พึ่ง Widgetbook เลย:
   ```bash
   flutter run -t lib/widgets/v3/<category>/preview_v3_<widget>.dart -d web-server --web-hostname 127.0.0.1 --web-port <port>
   ```
4. อ่าน process output จนเจอ URL ที่ serve จริง (เช่น `http://127.0.0.1:<port>`) แล้วส่ง URL นั้นให้ผู้ใช้เปิดในเบราว์เซอร์ของตัวเอง
5. คง dev server ไว้ตลอด session; ปิดเมื่อผู้ใช้บอกว่าเสร็จแล้ว หรือก่อนจะรัน component อื่นบน port เดิม

Guardrail เฉพาะ flow นี้: ห้ามแก้ `lib/widgetbook.dart`, `lib/widgetbook_use_cases.dart`, หรือ `lib/widgetbook.directories.g.dart` เพราะ flow นี้ใช้แค่ `preview_v3_*.dart` ของ widget เอง; ห้ามใช้ port ที่ถูกจองโดย dev server อื่นอยู่แล้ว; ห้ามรัน path ที่ยังไม่มีไฟล์จริง

## Canonical Workflow — `flutter-widget-v3-figma-to-code`

1. อ่าน design/handoff ที่ user ให้มา
2. `get_v3_figma_to_flutter_mapping` แมป component name ไปยัง Widget V3 ที่มีอยู่แล้ว (ถ้ามี ให้ใช้ `flutter-widget-v3-search`/`flutter-widget-v3-install` แทนการสร้างใหม่)
3. ถ้าไม่มี widget ตรงกัน ใช้ `list_v3_color_tokens` / `search_v3_color_tokens` / `get_v3_color_token` เพื่อ map สีไปยัง semantic token ที่ถูกต้อง
4. `get_v3_flutter_widget_template` scaffold widget ใหม่ (V3-prefixed template)
5. local/stdio อาจใช้ `generate_v3_widget_code` สำหรับ first-pass implementation; Remote MCP ให้ประกอบ source เองจาก template, token mapping และ codebase patterns
6. สร้าง preview ตาม `flutter-widget-v3-preview` workflow หลัง implementation เสร็จ

## Canonical Workflow — `flutter-widget-v3-audit`

1. ระบุ widget V3 เป้าหมาย, preview, docs, tests
2. `audit_v3_widget` ตรวจ legacy theme imports, raw `Color(...)`, ขาด `V3ThemeScope`, ขาด preview/metadata
3. `get_v3_widget_metadata` และ `get_v3_design_system_info`/`get_v3_codebase_patterns` เทียบกับ convention
4. `get_v3_widget_preview` ตรวจว่า preview ยังใช้งานได้และ cover Light/Dark
5. เรียง finding ตาม severity; แก้ปัญหาที่ปลอดภัยที่สุดก่อนถ้าถูกขอให้แก้

## Canonical Workflow — `flutter-widget-v3-upgrade`

1. ระบุ widget V3 local ที่มาจาก/คล้าย MCP source
2. ดึง `get_v3_widget_metadata`, `get_v3_widget_code`, `get_v3_widget_preview` ล่าสุดจาก MCP
3. Diff local กับ MCP source
4. แยก local customization / upstream improvement / breaking change
5. Upgrade แบบ selective sync; คง local business customization ไว้เมื่อเป็นไปได้
6. ถ้า drift มากเกินไป แนะนำ `flutter-widget-v3-install` ใหม่ + `flutter-widget-v3-adapt` แทนการ patch ทีละจุด

## Universal Guardrails (ทุก skill)

- ห้าม migrate หรือ overwrite widget เดิมที่อยู่นอก `lib/widgets/v3/**` โดยอัตโนมัติ ไม่ว่า workflow ใด
- ห้ามใช้ legacy theme (`ThemeColors.get()`, `theme_color.dart`) ภายในไฟล์ V3 ใด ๆ
- ทำงานเฉพาะ path ที่มี `v3` ชัดเจน: `lib/widgets/v3/**`, `test/widgets/v3/**`, และอ่าน (ไม่แก้) `lib/config/themes/v3/**`
- เรียกเฉพาะ MCP tool ที่มี prefix `v3` หรือ `_v3_`; ห้ามเรียก legacy tool เป็น fallback เมื่อ V3 tool ไม่พบข้อมูล — ให้รายงานว่าไม่พบและแนะนำ `flutter-widget-v3-beginner`/`flutter-widget-v3-figma-to-code` แทน
- ตรวจ Light/Dark, preview, tests, และ local guide (`V3_<WIDGET>_GUIDE.md` พร้อม `V3 Metadata` section) ก่อนถือว่างานเสร็จ
- `flutter-widget-v3-beginner` ต้องใช้ flow `ask → scan → summarize → confirm → execute` เท่านั้น และห้ามแก้ไฟล์ก่อนยืนยัน scope
- generation tools เป็น optional local/stdio optimization เท่านั้น; ทุก workflow ต้องมี remote-safe path ที่ทำงานต่อได้ด้วย read-only V3 tools โดยไม่ fallback ไป legacy

## Traceability

- Legacy skill spec ต้นแบบสำหรับ beginner flow: `mcp-server/FLUTTER_WIDGET_BEGINNER_SKILL_SPEC.md`
- Widget V3 convention ที่ skills ต้องยึด: `docs/v3/V3_WIDGET_CONVENTIONS.md`
- MCP V3 tool contracts: `mcp-server/v3/tool_contracts.js`
- Native packaging: `skills-v3/codex/.codex/skills/`, `skills-v3/claude-code/.claude/skills/`, `skills-v3/kiro/.kiro/skills/`
- Validation evidence: `docs/v3/V3_SKILLS_VALIDATION.md`
