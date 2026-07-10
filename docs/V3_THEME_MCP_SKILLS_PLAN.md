# Theme V3 + MCP + Skills Plan

สร้างเมื่อ: `2026-07-10 21:49:05 +0700`

## Goal

เพิ่ม Theme V3, Widget V3, MCP tools V3 และ Skills V3 แบบ additive ใน repo เดิม โดยคง behavior และ contract ของ Theme, Widgets, MCP tools และ Skills เดิมไว้ และเผยแพร่ V3 ผ่าน Remote Streamable HTTP service เดิมบน Render:

```text
https://flutter-widget-wallet-mcp.onrender.com/mcp
```

Execution checklist ของแผนนี้อยู่ที่ [`task/V3_THEME_MCP_SKILLS_TASKS.md`](../task/V3_THEME_MCP_SKILLS_TASKS.md)

## Assumptions And Decisions

- Theme เดิมใต้ `lib/config/themes/` เป็น legacy-stable และห้าม migrate หรือเปลี่ยน behavior ในงาน V3
- Widget เดิมที่อยู่นอก `lib/widgets/v3/` ต้องไม่ถูก migrate อัตโนมัติ
- V3 ใช้ `primitive.tokens.json` และ semantic Light/Dark tokens จาก Figma/DTCG เป็น source of truth
- V3 ใช้ path และ public API แยก โดยทุก public class ขึ้นต้นด้วย `V3`
- MCP ใช้ service เดิม, endpoint เดิม และ Bearer token mechanism เดิม ไม่สร้าง Render service ตัวที่สอง
- MCP runtime เดิมแก้ได้เฉพาะ additive registration/integration ที่จำเป็นต่อ V3 และต้องผ่าน legacy regression gates
- MCP V3 tools เป็น read-only และใช้ชื่อที่มี `v3` ชัดเจน
- Skills เดิมไม่แก้; Skills V3 เป็น distribution แยกและเรียก V3 tools จาก MCP endpoint เดิม
- V3 เริ่มจาก pilot widget หนึ่งตัวก่อนขยายไปยัง widget ชุดใหม่

## Non-Goals

- ไม่ย้ายหรือเปลี่ยน `theme.json`, `theme_color.dart`, `theme_generator.dart`, `base_theme.dart` และ `theme_constants.dart` เดิม
- ไม่เปลี่ยนชื่อ, required arguments, response fields หรือ error semantics ของ MCP tools เดิม
- ไม่ migrate widget เดิมไป V3
- ไม่เพิ่ม Render service, URL, custom domain หรือ auth secret ชุดใหม่
- ไม่ทำให้ MCP remote expose generation/write tools
- ไม่แก้ generated files ด้วยมือ

## Target Architecture

```text
Figma/DTCG token exports
├── primitive.tokens.json
├── semantic/light.tokens.json
└── semantic/dark.tokens.json
              │
              ▼
lib/config/themes/v3/
├── source tokens
├── validator + generator
├── generated primitive colors
├── generated semantic palettes
└── V3ThemeScope
              │
              ▼
lib/widgets/v3/**
├── widget source
├── standalone preview
├── local guide/spec
└── tests
              │
              ▼
mcp-server/ (service เดิม)
├── legacy registry + handlers เดิม
└── v3/ parser, catalog, handlers และ read-only contracts
              │
              ▼
https://flutter-widget-wallet-mcp.onrender.com/mcp
├── legacy tools
└── V3 tools
              │
              ▼
skills/ เดิม + skills-v3/ ชุดใหม่
```

## Phase 1 — Freeze Baseline And Boundaries

ก่อนเพิ่ม V3 ต้องเก็บ baseline ของ Flutter และ MCP เดิม เพื่อใช้ตรวจ regression ภายหลัง

Baseline commands:

```bash
flutter analyze
flutter test

cd mcp-server
npm run check:mcp-syntax
npm test
npm run verify:mcp
npm run verify:mcp:http
```

ต้องบันทึกอย่างน้อย:

- ผล `tools/list` และ tool contract snapshot เดิม
- ผล success/error ของ tools หลัก โดยเฉพาะ `get_color_token`
- รายการไฟล์ legacy ที่ห้ามเปลี่ยน behavior
- จำนวน read-only tools ที่ remote endpoint expose ก่อนเพิ่ม V3

Allowed change boundaries:

```text
lib/config/themes/v3/**
lib/widgets/v3/**
test/config/themes/v3/**
test/widgets/v3/**
mcp-server/v3/**
mcp-server/tests/v3/**
skills-v3/**
docs/v3/**
```

Existing MCP integration files แก้ได้แบบ additive เท่านั้น เช่น `app.js`, `tool_contracts.js`, `remote_support.js`, verify scripts และ `package.json`

## Phase 2 — Build Theme V3 Foundation

เพิ่มโครงสร้าง:

```text
lib/config/themes/v3/
├── tokens/
│   ├── primitive.tokens.json
│   └── semantic/
│       ├── light.tokens.json
│       └── dark.tokens.json
├── generated/
│   ├── v3_primitive_colors.g.dart
│   └── v3_semantic_colors.g.dart
├── v3_color_token.dart
├── v3_color_palette.dart
├── v3_theme_scope.dart
├── v3_theme_generator.dart
└── README.md
```

Source-of-truth rules:

- `tokens/**` เป็น editable inputs
- `generated/**` เป็น derived outputs และห้ามแก้ด้วยมือ
- Primitive tokens เป็นฐานข้อมูลสี
- Widgets ใช้ semantic tokens เป็นค่าเริ่มต้น
- V3 ห้าม import `theme_color.dart` หรือเรียก `ThemeColors.get()`

Runtime API ที่ต้องการ:

```dart
final colors = V3ThemeScope.colorsOf(context);

return Container(
  color: colors.backgroundPrimary,
  child: Text(
    'Title',
    style: TextStyle(color: colors.contentPrimary),
  ),
);
```

ใช้ `Theme.of(context).brightness` ใน `V3ThemeScope` เพื่อไม่ต้องแก้ `ThemeData` หรือ theme bootstrap เดิม

## Phase 3 — Implement V3 Token Validation And Generation

Generator ต้องรองรับ:

- `$type: "color"`
- `$value.hex`, `$value.alpha`, `colorSpace` และ `components`
- `$extensions.com.figma.aliasData`
- alias แบบ `{Core.white}`
- primitive references เช่น `Slate/900`
- path normalization เช่น `Content/Primary` → `content/primary`
- Dart property mapping เช่น `background/extension/blue` → `backgroundExtensionBlue`

Generator ต้อง fail แบบ actionable เมื่อ:

- JSON หรือ token schema ไม่ถูกต้อง
- HEX/alpha ไม่ถูกต้อง
- Light/Dark semantic paths ไม่ตรงกัน
- token ซ้ำหลัง normalize
- semantic alias อ้าง primitive ที่ไม่มี
- alias cycle เกิดขึ้น
- Dart property names ชนกัน
- semantic token ไม่มี resolved color

Expected outputs:

```dart
abstract final class V3PrimitiveColors {
  static const slate900 = Color(0xFF0F172A);
  static const white = Color(0xFFFFFFFF);
}
```

```dart
final class V3ColorPalette {
  const V3ColorPalette({
    required this.contentPrimary,
    required this.backgroundPrimary,
  });

  final Color contentPrimary;
  final Color backgroundPrimary;

  static const light = V3ColorPalette(/* generated mappings */);
  static const dark = V3ColorPalette(/* generated mappings */);
}
```

Generator ต้อง deterministic: เมื่อ inputs ไม่เปลี่ยน การรันซ้ำต้องไม่สร้าง diff

## Phase 4 — Establish Widget V3 Conventions And Pilot

Widget ใหม่ที่ใช้ V3 อยู่ใต้:

```text
lib/widgets/v3/<category>/
├── v3_<widget>.dart
├── preview_v3_<widget>.dart
└── V3_<WIDGET>_GUIDE.md

test/widgets/v3/<category>/
└── v3_<widget>_test.dart
```

Widget V3 rules:

- ใช้ `V3ThemeScope.colorsOf(context)`
- ห้าม import legacy theme
- ห้ามใช้ raw `Color(...)` เมื่อ semantic token ครอบคลุม
- ห้ามใช้ primitive โดยตรงสำหรับสีเชิงหน้าที่ เว้นแต่เอกสาร design ระบุอย่างชัดเจน
- รองรับ Light/Dark, accessibility, readable typography และ localization
- มี standalone preview, tests และ local documentation
- Local guide ต้องประกาศ `Theme system: V3` และรายการ semantic tokens ที่ใช้

Pilot ต้องมีอย่างน้อยหนึ่ง reusable widget ที่พิสูจน์:

- theme switching
- semantic token consumption
- preview usability
- widget tests
- MCP discovery/metadata

## Phase 5 — Add V3 To The Existing MCP Server

เพิ่ม module แยก:

```text
mcp-server/v3/
├── token_parser.js
├── token_resolver.js
├── token_catalog.js
├── widget_parser.js
├── widget_catalog.js
├── tool_contracts.js
└── handlers.js
```

MCP V3 อ่านเฉพาะ:

```text
lib/config/themes/v3/tokens/**
lib/config/themes/v3/generated/**
lib/widgets/v3/**
```

V3 tools ที่วางแผนไว้:

```text
list_v3_color_tokens
search_v3_color_tokens
get_v3_color_token
list_v3_widgets
search_v3_widgets
get_v3_widget_metadata
get_v3_widget_code
get_v3_widget_preview
audit_v3_widget
```

ตัวอย่าง `get_v3_color_token`:

```json
{
  "tokenName": "content/primary",
  "mode": "both"
}
```

```json
{
  "themeVersion": "v3",
  "tokenName": "content/primary",
  "dartProperty": "contentPrimary",
  "lightValue": "#0F172A",
  "darkValue": "#FFFFFF",
  "lightPrimitiveAlias": "Slate/900",
  "darkPrimitiveAlias": "White",
  "dartUsage": "V3ThemeScope.colorsOf(context).contentPrimary"
}
```

Compatibility rules:

- `get_color_token` ยังอ่าน legacy `theme.json` และคืน shape เดิม
- ห้ามลบหรือเปลี่ยน type ของ documented response fields เดิม
- ห้ามเพิ่ม required argument ให้ tools เดิม
- V3 tools ทุกตัวต้องมี read-only annotations เพื่อให้ remote registry expose ผ่าน endpoint เดิม
- Generation/write tools ของเดิมยังไม่ถูก expose ใน remote mode

## Phase 6 — Publish Skills V3 Against The Same Remote MCP

เพิ่ม skill distributions แยก:

```text
skills-v3/
├── codex/.codex/skills/
├── claude-code/.claude/skills/
└── kiro/.kiro/skills/
```

Skills ที่วางแผนไว้:

```text
flutter-widget-v3-search
flutter-widget-v3-install
flutter-widget-v3-adapt
flutter-widget-v3-preview
flutter-widget-v3-figma-to-code
flutter-widget-v3-audit
flutter-widget-v3-upgrade
```

ทุก skill ใช้ MCP config เดิม:

```text
Server: flutter-widget-wallet-mcp
Endpoint: https://flutter-widget-wallet-mcp.onrender.com/mcp
Auth: Authorization: Bearer <TOKEN>
```

Skill routing:

| Skill | V3 tools หลัก |
|---|---|
| `v3-search` | `search_v3_widgets`, `get_v3_widget_metadata` |
| `v3-install` | `get_v3_widget_code`, `get_v3_widget_preview` |
| `v3-adapt` | `get_v3_color_token`, token search |
| `v3-preview` | `get_v3_widget_preview` |
| `v3-figma-to-code` | token search + `get_v3_color_token` |
| `v3-audit` | `audit_v3_widget`, metadata |
| `v3-upgrade` | metadata/source comparison |

Skills V3 ต้องบังคับ:

- ทำงานเฉพาะ `lib/widgets/v3/**`
- ห้าม migrate หรือ overwrite widget เดิม
- ห้ามใช้ legacy theme ใน V3
- ตรวจ Light/Dark, preview, tests และ docs
- เรียก V3 token tool เมื่อ token ไม่แน่ชัด

## Phase 7 — Verify And Roll Out On The Existing Render Service

คง Render service เดิม:

```text
Service: flutter-widget-wallet-mcp
URL: https://flutter-widget-wallet-mcp.onrender.com
MCP endpoint: /mcp
Root directory: mcp-server
Build: npm ci
Start: node http-server.js
Health: /health
```

Client config ไม่เปลี่ยน:

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp": {
      "url": "https://flutter-widget-wallet-mcp.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer <TOKEN>"
      }
    }
  }
}
```

Render auto-deploy/include paths ต้องครอบคลุม:

```text
mcp-server/**
lib/config/themes/v3/**
lib/widgets/v3/**
```

ไม่ต้องให้ `skills-v3/**` trigger deploy เพราะ skills ทำงานฝั่ง client

Verification gates:

```bash
flutter analyze
flutter test

cd mcp-server
npm run check:mcp-syntax
npm test
npm run verify:mcp
npm run verify:mcp:http
npm run ci:mcp
```

Remote verification ต้องตรวจอย่างน้อย:

- `/health` และ `/info` ชี้ commit ที่ deploy จริง
- legacy tools ยังทำงานและ contract เดิมผ่าน
- V3 tools ปรากฏใน `tools/list` และ `/info`
- `get_v3_color_token` คืน Light/Dark + primitive aliases ถูกต้อง
- V3 widget discovery/code/preview ทำงาน
- unauthenticated requests ยังถูก reject
- write/generation tools ยังไม่ถูก expose

Rollout เริ่มจาก pilot widget เดียว แล้วจึงเปิดใช้ V3 สำหรับ widget ใหม่ทั้งหมด

## Validation Matrix

| Area | Required evidence |
|---|---|
| Legacy Flutter | `flutter analyze`, `flutter test` ผ่าน |
| V3 tokens | token counts, parity, alias และ deterministic generation tests |
| V3 widgets | Light/Dark preview, widget tests, local guide |
| Legacy MCP | contract/snapshot/integration tests ผ่านโดย behavior เดิมไม่เปลี่ยน |
| V3 MCP | parser/catalog/tool/remote tests ผ่าน |
| Skills | native packs ครบและเรียกเฉพาะ V3 tools |
| Render | `/health`, `/info`, remote verifier และ deployed commit ตรงกัน |

## Main Risk And Mitigation

ความเสี่ยงสูงสุดคือ V3 และ legacy routing ปะปนกัน ทำให้ widget ใหม่ใช้ token เดิม หรือการเพิ่ม V3 registry กระทบ MCP contract ที่ publish แล้ว

Mitigation:

- ใช้ `v3` ใน path, class, tool และ skill names ทุกจุด
- MCP V3 อ่านเฉพาะ V3 paths และห้าม fallback ไป legacy theme
- CI ห้าม V3 import `theme_color.dart` และห้าม widget เดิม import V3
- เก็บ legacy tool snapshots และ baseline เป็น regression gate
- เพิ่ม MCP registration แบบ additive เท่านั้น
- deploy pilot widget ก่อนเปิดใช้กับงานใหม่ทั้งหมด
- rollback ด้วย deployed commit โดยไม่เปลี่ยน URL หรือ Bearer tokens

## Rollback Strategy

หาก V3 มีปัญหา:

1. Rollback Render ไป commit ก่อนเพิ่ม V3
2. คง URL, service และ secrets เดิม
3. Legacy tools/widgets/themes ยังคงทำงานตาม baseline
4. แก้ V3 ใน branch แยกและรัน validation ใหม่ก่อน deploy

## Exit Criteria

- Theme V3 ใช้ primitive + semantic Light/Dark sources ได้จริง
- V3 generator deterministic และ validation ครบ
- Pilot widget V3 ผ่าน preview/test/docs/accessibility checks
- MCP endpoint เดิม expose legacy + V3 read-only tools
- Legacy MCP contracts และ behavior ไม่เปลี่ยน
- Skills V3 ครบสำหรับ Codex, Claude Code และ Kiro โดย skills เดิมไม่เปลี่ยน
- Render service เดิมผ่าน remote verification และ freshness metadata ตรงกับ deploy
- เอกสาร onboarding ระบุชัดว่า URL/Bearer token เดิมใช้ได้กับทั้ง legacy และ V3
