# Widget V3 Lucide Icon Integration Plan

สร้างเมื่อ: `2026-07-16 01:24:58 +0700`

## Goal

สร้าง `V3LucideIcon` ที่ import Lucide ได้ง่ายเหมือน Flutter `Icon` แต่ควบคุม size, stroke, semantic color, accessibility และ SVG override ให้ตรง Figma โดยไม่ผูก reusable Widget V3 แต่ละตัวกับ Lucide package โดยตรง

Execution checklist อยู่ที่ [`task/V3_LUCIDE_ICON_TASKS.md`](../task/V3_LUCIDE_ICON_TASKS.md)

## User Requirements

- เรียก icon จาก Lucide library และค้นด้วยชื่อ Lucide ได้ง่าย
- ควบคุม size/stroke ตาม Figma component spec
- ใช้ official Lucide SVG override ได้เมื่อ package renderer ไม่ตรง Figma
- สีและ state ไหลจาก `IconTheme`/Theme V3 โดยไม่ hardcode
- Navigation, MiniButton และ Widget V3 อื่นคง API แบบรับ `Widget`
- มี mapping และ resolved values สำหรับ audit Figma ถึง Flutter

## Decisions

- ใช้ `lucide_icons_flutter` เป็น candidate default renderer; LI-01 ต้องยืนยัน SDK compatibility, API, license และ upstream Lucide version ก่อน pin
- สร้าง `V3LucideIcon` เป็น adapter กลาง ห้าม reusable Widget V3 อื่น import package โดยตรง
- package renderer เป็น default; official Lucide SVG ใช้เฉพาะ verified exceptions
- SVG override ต้อง checked-in แบบเลือกเฉพาะไฟล์, pin upstream source/version และ render ผ่าน `flutter_svg`
- `V3Navigation` เป็น pilot เพราะมี sizes 24/32px, semantic states และ Light/Dark preview พร้อม
- public APIs ของ `V3Navigation`/`V3MiniButton` ต้องไม่เปลี่ยน

## Non-Goals

- copy Lucide SVG ทั้ง repository
- เปลี่ยน icon ใน legacy widgets
- สร้าง parallel icon color/spacing theme
- บังคับทุก consumer ใช้ Lucide
- hardcode raw colors, arbitrary sizes หรือ strokes ใน consuming widgets
- publish MCP/preview bundle ก่อน local verification ผ่าน

## Target Architecture

```text
lucide_icons_flutter              official Lucide SVG (exceptions only)
          │                                      │
          └──────────────────┬───────────────────┘
                             ▼
                   lib/widgets/v3/icon/
                   ├── v3_lucide_icon.dart
                   ├── v3_icon_size.dart
                   ├── v3_icon_stroke.dart
                   ├── preview_v3_lucide_icon.dart
                   └── V3_LUCIDE_ICON_GUIDE.md
                             │
                             ▼
             Widget-typed slots in reusable Widget V3
```

## Public API Contract

```dart
const V3LucideIcon(
  LucideIcons.house,
  size: V3IconSize.medium,
  stroke: V3IconStroke.regular,
)
```

Figma-specific override:

```dart
const V3LucideIcon(
  LucideIcons.scanLine,
  size: V3IconSize.large,
  stroke: V3IconStroke.light,
  svgAsset: 'lib/assets/icons/v3/lucide/scan-line.svg',
)
```

Resolution priority:

```text
explicit property → inherited IconTheme → documented V3 default
```

Render priority:

```text
svgAsset present → flutter_svg
svgAsset absent  → lucide_icons_flutter
```

## Token Contract

| Size role | Value | Initial usage |
|---|---:|---|
| `tiny` | 12px | Mini Button |
| `small` | 16px | compact controls |
| `medium` | 24px | Navigation destinations |
| `large` | 32px | Navigation Scan |

| Stroke role | Design intent |
|---|---:|
| `thin` | 1px |
| `light` | 1.5px |
| `regular` | 2px |
| `bold` | 2.5px |

LI-01 ต้องยืนยัน mapping กับ package renderer หาก discrete weight ไม่ตรง ให้บันทึกข้อจำกัดและใช้ SVG override เมื่อ Figma ต้องการ exact stroke

## Accessibility Contract

- icon ใน button/navigation slots เป็น decorative โดย default เพื่อไม่สร้าง semantics ซ้ำ
- standalone icon-only action ต้องรับ localized semantic label จาก caller
- SVG และ package renderer ต้องมี semantics behavior เดียวกัน
- ห้ามฝัง user-facing English label ใน reusable icon component

## Implementation Phases

### Phase 1 — Dependency And Rendering Spike

- ตรวจ package กับ Flutter/Dart SDK, license และ upstream version
- render package เทียบ official SVG ที่ 12/16/24/32px
- เปรียบเทียบ stroke, cap/join, viewBox, baseline และ build impact

Expected result: มีหลักฐานเลือก renderer และเกณฑ์ใช้ SVG override

### Phase 2 — Build The V3 Adapter

- เพิ่ม `V3IconSize`, `V3IconStroke`, `V3LucideIcon`
- inherit color/size จาก `IconTheme`
- map stroke อย่าง deterministic
- รองรับ package/SVG ผ่าน public API เดียว

Expected result: parent Widget V3 ควบคุม semantic color ได้ทั้งสอง renderer

### Phase 3 — Preview, Guide And Audit Mapping

- preview ทุก size/stroke, package-vs-SVG และ Light/Dark
- Figma-to-Lucide table: node, icon, size, stroke, renderer, upstream version, override reason
- Token Audit Values และ generated preview registry

Expected result: เลือกและ audit icon ได้จาก preview/guide เดียว

### Phase 4 — Navigation Pilot

- map Home, Card, Services, Menu และ Scan
- เปลี่ยน preview icons โดยคง reusable API เป็น `Widget`
- ใช้ SVG เฉพาะ verified mismatch
- ตรวจ 24/32px, semantic states และ optical alignment บน Simulator

Expected result: adapter ผ่าน component จริงใน Light/Dark

### Phase 5 — MiniButton And Adoption Guidance

- เปลี่ยน preview/guide examples โดยไม่เปลี่ยน runtime API
- ระบุ recipe สำหรับ Widget V3 ใหม่
- ไม่ migrate legacy/production consumers แบบกว้างโดยไม่มี task แยก

### Phase 6 — Verification

```bash
flutter pub get
dart format lib/widgets/v3/icon test/widgets/v3/icon
flutter analyze
flutter test test/widgets/v3/icon/
flutter test test/widgets/v3/
npm run check:v3-boundaries
dart run tool/generate_v3_preview_registry.dart --check
flutter build web --release -t lib/preview_v3/main.dart
```

ตรวจจริงบน iOS Simulator ทั้ง Light/Dark, package/SVG ที่ทุก size, Navigation states และ semantics

## Exit Criteria

- `V3LucideIcon(LucideIcons.*)` ใช้งานง่าย
- size/stroke mapping มี contract/tests
- package/SVG inherit `IconTheme` เหมือนกัน
- Navigation pilot ตรง Figma ใน Light/Dark
- Widget V3 public APIs เดิมไม่แตก
- docs มี mapping, primitive values, upstream/version และ override reasons
- preview registry, analyze, tests, boundaries และ web build ผ่าน
- ไม่มี direct Lucide import ใน reusable Widget V3 อื่น

## Main Risk And Mitigation

ความเสี่ยงสูงสุดคือ package renderer/discrete weights ไม่ตรง official SVG/Figma ในบางขนาด

- ทำ rendering spike ก่อน finalize API
- pin dependency และ upstream icon version
- ใช้ official SVG เฉพาะ verified exceptions
- ซ่อน renderer หลัง `V3LucideIcon`
- gate adoption ด้วย Navigation pilot และ real-device visual evidence
