# Widget V3 Preview Publishing Guide

เอกสารนี้เป็น context guide และ operational source of truth สำหรับการเพิ่ม Widget V3 ใหม่ให้:

- เปิดได้ผ่าน local Flutter Web preview host ใน source repo
- ถูกค้นพบโดย hosted MCP
- เปิดได้จาก `flutter-widget-v3-preview` ใน published consumer mode โดย consumer repo ไม่ต้องมี Flutter หรือ Dart

เอกสารที่เกี่ยวข้อง:

- Widget conventions: [`V3_WIDGET_CONVENTIONS.md`](./V3_WIDGET_CONVENTIONS.md)
- Zero-Flutter contract: [`V3_ZERO_FLUTTER_PREVIEW_CONTRACT.md`](./V3_ZERO_FLUTTER_PREVIEW_CONTRACT.md)
- Rollout/rollback: [`V3_ZERO_FLUTTER_PREVIEW_ROLLOUT.md`](./V3_ZERO_FLUTTER_PREVIEW_ROLLOUT.md)
- Source preview architecture: [`../V3_WEB_PREVIEW_PLAN.md`](../V3_WEB_PREVIEW_PLAN.md)

## What Is Automatic

เมื่อโครงสร้างและชื่อไฟล์ถูกต้อง ระบบจะทำงานต่อให้อัตโนมัติดังนี้:

1. `tool/generate_v3_preview_registry.dart` ค้นหา `lib/widgets/v3/**/preview_v3_*.dart`
2. generated registry สร้าง slug `<category>/<WidgetClass>`
3. MCP catalog ค้นหา widget source ที่ขึ้นต้นด้วย `v3_` ใต้ `lib/widgets/v3/**`
4. CI build Flutter Web bundle หนึ่งชุดที่ครอบคลุมทุก registered slug
5. hosted MCP ส่ง `previewSlug` และ `previewDelivery` ให้ Skill
6. `flutter-widget-v3-preview` ดาวน์โหลด ตรวจ checksum และเปิด bundle จาก user cache บน `127.0.0.1`

## Required Widget V3 Component Files

ก่อน publish ทุก component folder ใต้ `lib/widgets/v3/<category>/` ต้องมีชุดไฟล์ขั้นต่ำครบตาม canonical example `lib/widgets/v3/button/`:

```text
<component>-_base.json
<component>.md
preview_v3_<widget>.dart
v3_<widget>.dart
V3_<WIDGET>_GUIDE.md
```

- base JSON และ component Markdown ต้องใช้ basename/component slug/identity เดียวกัน
- เมื่อแทนที่ base JSON ต้อง regenerate component Markdown และตรวจ render-meta `sourceHash`
- preview Dart ต้องตรง naming convention เพื่อให้ registry generator discover ได้
- targeted tests ใต้ `test/widgets/v3/<category>/` ยังเป็น requirement เพิ่มเติมก่อน publish

ไม่ต้องแก้ `SKILL.md`, launcher, preview router หรือ MCP handler แยกสำหรับ widget แต่ละตัว

## Required File Set

ตัวอย่าง Widget `V3NewCard` ใน category `card`:

```text
lib/widgets/v3/card/
├── v3_new_card.dart
├── preview_v3_new_card.dart
└── V3_NEW_CARD_GUIDE.md

test/widgets/v3/card/
└── v3_new_card_test.dart
```

Widget source ต้องใช้ public class ที่สอดคล้องกับชื่อไฟล์:

```dart
class V3NewCard extends StatelessWidget {
  const V3NewCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Theme V3 semantic APIs and caller-owned localized copy.
    return const SizedBox();
  }
}
```

Preview filename และ preview class ต้องตรงกับ convention:

```dart
class V3NewCardPreview extends StatelessWidget {
  const V3NewCardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const V3NewCard();
  }
}
```

Generator จะ derive:

```text
File:     preview_v3_new_card.dart
Widget:   V3NewCard
Preview:  V3NewCardPreview
Category: card
Slug:     card/V3NewCard
```

ข้อกำหนดสำคัญ:

- category มาจากชื่อ immediate parent directory
- preview file ต้องขึ้นต้นด้วย `preview_v3_` และลงท้าย `.dart`
- preview class ต้องเป็น `<WidgetClass>Preview`
- preview class ต้องสร้างผ่าน `const` ได้ เพราะ generated registry ใช้ `const <PreviewClass>()`
- slug ต้องไม่ซ้ำกับ preview อื่น
- local guide ต้องมี `V3 Metadata` ตาม `V3_WIDGET_CONVENTIONS.md`
- Widget V3 ต้องใช้ Theme V3 เท่านั้น ห้าม import legacy theme หรือเรียก `ThemeColors.get()`

## Source-Development Workflow

ใช้ flow นี้สำหรับตรวจ working tree ก่อน publish:

1. เพิ่มหรือแก้ widget, preview, local guide และ targeted tests
2. Generate registry:

   ```bash
   dart run tool/generate_v3_preview_registry.dart
   ```

3. Commit generated output `lib/preview_v3/preview_registry.g.dart` พร้อม source ห้ามแก้ไฟล์นี้ด้วยมือ
4. ตรวจ registry และโค้ด:

   ```bash
   dart run tool/generate_v3_preview_registry.dart --check
   flutter analyze
   flutter test test/preview_v3/ test/tool/ test/widgets/v3/<category>/
   ```

5. เปิด local host:

   ```bash
   ./scripts/serve-v3-preview.sh --slug <category>/<WidgetClass>
   ```

6. ตรวจ Light/Dark, states, interaction, narrow viewport, accessibility และ asset loading ตาม widget spec

หากต้องการดู uncommitted changes ต้องใช้ source-development mode บนเครื่องที่มี Flutter เท่านั้น Published consumer mode ไม่รองรับ hot reload ของ source ที่ยังไม่ publish

## Published Consumer Workflow

Published preview จะพร้อมให้ `flutter-widget-v3-preview` ใช้เมื่อครบทุกขั้นตอนต่อไปนี้:

1. Merge source, preview และ generated registry เข้า `main`
2. `.github/workflows/v3-preview-bundle.yml` ผ่านทุก gate
3. workflow publish GitHub Releases:
   - `v3-preview-<full-source-sha>` สำหรับ immutable bundle
   - `v3-preview-latest` สำหรับ latest pointer
4. Render service เดิม deploy source commit เดียวกัน เพื่อให้ MCP catalog เห็น widget ใหม่
5. ค่า `MCP_REMOTE_COMMIT_SHA` ต้องตรงกับ Render deployed commit และ bundle `sourceCommit`
6. `/info.previewBundle` ต้องรายงาน `available:true` และ `fresh:true`
7. Remote verifier ต้องผ่าน:

   ```bash
   cd mcp-server
   MCP_REMOTE_BASE_URL="https://flutter-widget-wallet-mcp.onrender.com/mcp" \
   MCP_REMOTE_BEARER_TOKEN="<token>" \
   npm run verify:mcp:remote:v3
   ```

Bearer token เป็น secret ห้ามเขียนลงไฟล์ tracked, URL, log, manifest หรือเอกสาร

## Freshness Invariant

ค่าต่อไปนี้ต้องอ้างถึง full commit SHA เดียวกัน:

```text
Render deployed source
      = MCP_REMOTE_COMMIT_SHA
      = /health and /info freshness commit
      = bundle manifest sourceCommit
      = previewDelivery.sourceCommit
```

ถ้าไม่ตรงกัน ระบบต้อง fail closed ด้วย `STALE_BUNDLE` และห้าม fallback ไป bundle เก่าแบบเงียบ ๆ

## Definition Of Done

- [ ] component folder มี base JSON, component Markdown, widget Dart, preview Dart และ V3 guide ครบ
- [ ] base JSON/component Markdown มี basename, component slug, identity และ render-meta `sourceHash` ตรงกัน
- [ ] targeted tests อยู่ใน path ตาม convention
- [ ] preview แสดง Light/Dark และ states สำคัญตาม design source of truth
- [ ] `dart run tool/generate_v3_preview_registry.dart --check` ผ่าน
- [ ] generated registry ถูก commit และไม่มี manual edit
- [ ] targeted tests และ `flutter analyze` ผ่าน
- [ ] local source-development URL เปิด slug ใหม่ได้จริง
- [ ] changes merge เข้า `main`
- [ ] bundle CI publish immutable release สำเร็จ
- [ ] Render deploy commit เดียวกับ bundle และ `MCP_REMOTE_COMMIT_SHA` ตรงกัน
- [ ] `/info.previewBundle` เป็น `available:true`, `fresh:true`
- [ ] `verify:mcp:remote:v3` ผ่าน
- [ ] เรียก `flutter-widget-v3-preview` จาก non-Flutter repo แล้วได้ URL หลัง readiness ผ่าน
- [ ] consumer worktree ไม่เปลี่ยนและไม่มี secret leakage

## Troubleshooting

| อาการ | สาเหตุที่ควรตรวจ | วิธีแก้ |
|---|---|---|
| Generator แจ้ง missing preview builder | ชื่อ class ไม่ตรง filename | เปลี่ยนเป็น `<WidgetClass>Preview` |
| CI แจ้ง registry stale | เพิ่ม/rename preview แต่ไม่ได้ regenerate | รัน generator และ commit `preview_registry.g.dart` |
| MCP หา widget ไม่เจอ | source ไม่ได้ใช้ `v3_*.dart`, ยังไม่ deploy หรือชื่อ class/parser ไม่ตรง | ตรวจ source convention แล้ว deploy Render commit ใหม่ |
| Skill ได้ `NOT_BUILT` | bundle workflow ยังไม่ publish หรือ bundle source ถูก disable | ตรวจ GitHub Actions/Release และ Render bundle config |
| Skill ได้ `STALE_BUNDLE` | MCP freshness กับ bundle commit ไม่ตรง | deploy/publish commit เดียวกันและแก้ `MCP_REMOTE_COMMIT_SHA` |
| Skill ได้ `UNAUTHORIZED` | bearer token หายหรือไม่ถูกต้อง | ใช้ token ผ่าน Authorization header เท่านั้น |
| Local URL เปิด widget ไม่พบ | slug/category ไม่ตรง generated registry | ตรวจ `preview_registry.g.dart` และใช้ `<category>/<WidgetClass>` |
| Preview build fail ที่ constructor | generated registry เรียก preview ด้วย `const` | เพิ่ม `const` constructor ให้ preview class |

## Ownership Boundaries

- แก้ widget/preview/guide/test เป็นหลัก ไม่แก้ Skill ต่อ widget
- `lib/preview_v3/preview_registry.g.dart` เป็น generated output
- `build/web/**` และ `dist/**` เป็น generated/untracked output ห้าม commit
- `mcp-server/v3/bundle_contract.js` คือ machine contract; ห้ามเปลี่ยน shape โดยไม่ bump `schemaVersion` และอัปเดต human contract
- คง `scripts/serve-v3-preview.sh` สำหรับ source-development mode
- ใช้ hosted Render service เดิม ห้ามสร้าง service ที่สองสำหรับ preview
