# V3 Small Button Guide

## V3SmallButton

Button component สำหรับ Theme V3 ที่รองรับเฉพาะ Figma `Size=Small` ครบ 3 variants × 4 states พร้อม optional left/right icons และ Light/Dark semantic colors ข้อความทั้งหมดมาจาก caller เพื่อรองรับ localization

`V3SmallButton` เป็นสมาชิกลำดับที่สองของตระกูล Button (ต่อจาก `V3MiniButton`) และแชร์ Figma component set node เดียวกัน (`18:1764`, `Size=Small`) — ดู `button-_base.json` และ `button.md` สำหรับข้อมูล cross-size ทั้งหมด

### Design Source Of Truth

- **Figma component set:** [`18:1764`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=18-1764) (`Size=Small`, ทุก hierarchy × state)
- **uSpec base JSON:** `lib/widgets/v3/button/button-_base.json` (`_meta.componentSlug: "button"`, ครอบคลุมทั้ง 4 sizes)
- **Generated component doc:** `lib/widgets/v3/button/button.md` — Structure/Color/Voice ของ Small อยู่ในคอลัมน์ "small" ของทุกตาราง
- Figma `State` variant axis ของ Small เก็บ `Default/Active/Disabled/Error` ครบทั้ง 4 ค่า (re-extract ล่าสุดวันที่ `2026-08-03`, node `18:1764`, 192 variants) — ยืนยันตรงกับที่ `V3MiniButton` ใช้อยู่แล้ว ไม่ใช่การอนุมานจาก "focus/active เท่ากันทุก size" อีกต่อไป: สี Primary Active (`#456cb9` = `border/tertiary`) ตรวจสอบแล้วว่าเหมือนกันทุก size จริงจาก `colorWalk`

Icon slots accept any `Widget`. `preview_v3_small_button.dart` ใช้ `V3LucideIcon` (ดู `V3_LUCIDE_ICON_GUIDE.md`) ที่ resolve ขนาด 16px จาก `IconTheme.merge` wrapper ของปุ่มโดยอัตโนมัติ — ไม่ต้องส่ง `size` เอง:

```dart
V3SmallButton(
  label: AppLocalizations.of(context)!.continueLabel,
  semanticLabel: AppLocalizations.of(context)!.continueLabel,
  variant: V3SmallButtonVariant.outline,
  leadingIcon: const V3LucideIcon(LucideIcons.arrowRight),
  trailingIcon: const V3LucideIcon(LucideIcons.chevronRight),
  onPressed: submit,
)
```

### Public API

| Property | Type | Default | Description |
|---|---|---|---|
| `label` | `String` | required | ข้อความ localized ที่แสดงบนปุ่ม |
| `onPressed` | `VoidCallback?` | `null` | callback; ค่า `null` ทำให้ปุ่ม disabled |
| `variant` | `V3SmallButtonVariant` | `primary` | `primary`, `outline` หรือ `ghost` |
| `state` | `V3SmallButtonState` | `defaultState` | `defaultState`, `active`, `disabled` หรือ `error` |
| `leadingIcon` | `Widget?` | `null` | icon ขนาด 16px นำหน้าข้อความ |
| `trailingIcon` | `Widget?` | `null` | icon ขนาด 16px ต่อท้ายข้อความ |
| `isLoading` | `bool` | `false` | แสดง progress และปิด interaction ชั่วคราว |
| `semanticLabel` | `String?` | `null` | label สำหรับ assistive technology; fallback เป็น `label` |
| `semanticHint` | `String?` | `null` | hint ที่ localized แล้วสำหรับ assistive technology |
| `tooltip` | `String?` | `null` | tooltip ที่ localized แล้วเมื่อจำเป็น |

### Figma Specification

| Variant | Height | Padding | Gap | Icon | Radius | Typography | Shadow |
|---|---:|---:|---:|---:|---|---|---|
| Primary | `36` (ไม่มี dimension token ในไฟล์ export ปัจจุบัน) | X `space-16`, Y `space-2` | `space-6` | `space-16` | `rounded-full` | `label/small` | none |
| Outline | `36` | X `space-16`, Y `space-2` | `space-6` | `space-16` | `rounded-full` | `label/small` | `shadow-sm` เฉพาะ Default/Active |
| Ghost | `space-20` | `space-0` | `space-6` | `space-16` | `rounded-full` | `label/small` + underline | none |

- ค่าทั้งหมดวัดจาก `button-_base.json`'s 192-variant walk (`Size=Small` group, 48 variants: 3 hierarchies × 4 states × 4 icon-visibility combinations) เทียบตรงกับ `button.md` Structure section
- ความสูง (`height`) ไม่มี dimension token ผูกอยู่ใน Figma export (`height.token == null` ทุก size แม้กระทั่ง Mini) จึงใช้ literal `36.0` แทน; ค่าอื่นทั้งหมดใช้ semantic token จริง
- Color/border logic สืบทอดจาก `V3MiniButton` ตาม `button.md`'s "Color tokens are independent of size" — Primary Active ใช้ `border/tertiary`, Outline Active ใช้ `core/black` alpha 5% + `content/neutral`, Outline Error แยกสี content `state/error` กับ border `border/extension/error`
- Disabled ปิด callback แม้ caller ส่ง `onPressed`; keyboard focus ใช้ visual เดียวกับ Active
- component ใช้ `V3Typography`, `V3Spacing`, `V3Radii`, `V3PrimitiveColors` และ `V3PrimitiveShadows` โดยตรง

### Accessibility

- Small มี visual height 36px (Ghost 20px) ตาม SOT
- รองรับ keyboard focus/activation, active semantics และ localized semantic label/hint
- label เป็นหนึ่งบรรทัด; caller ควรส่งข้อความสั้นและ localized
- ตรวจ preview ได้ด้วย `flutter run -t lib/widgets/v3/button/preview_v3_small_button.dart`

### Token Audit Values

| Semantic token | Light primitive / value | Dark primitive / value |
|---|---|---|
| `button/primary` | `Blue/800` · `#244EA2` | `Blue/800` · `#244EA2` |
| `button/secondary` | `White` · `#FFFFFF` | `Slate/800` · `#1E293B` |
| `background/neutral` | `Neutral/200` · `#E5E5E5` | `Neutral/400` · `#A3A3A3` |
| `border/tertiary` | `Blue/700` · `#456CB9` | `Blue/300` · `#CCDDFA` |
| `border/slate` | `Slate/400` · `#94A3B8` | `Blue/300` · `#CCDDFA` |
| `border/extension/info` | `Navy/500` · `#3B82F6` | `Navy/500` · `#3B82F6` |
| `border/extension/error` | `Red/500` · `#EF4444` | `Red/500` · `#EF4444` |
| `content/primary` | `Slate/900` · `#0F172A` | `White` · `#FFFFFF` |
| `content/white` | `White` · `#FFFFFF` | `White` · `#FFFFFF` |
| `content/neutral` | `Neutral/400` · `#A3A3A3` | `Neutral/400` · `#A3A3A3` |
| `content/neutral2` | `Neutral/700` · `#404040` | `Neutral/50` · `#FAFAFA` |
| `content/extension/navy` | `Navy/700` · `#1D4ED8` | `Navy/400` · `#60A5FA` |
| `core/black` | `Black` · `#000000` | `White` · `#FFFFFF` |
| `state/error` | `Red/600` · `#DC2626` | `Red/400` · `#F87171` |

| Dimension token | Primitive value |
|---|---:|
| `space-0` | `0px` |
| `space-2` | `2px` |
| `space-6` | `6px` |
| `space-16` | `16px` |
| `space-20` | `20px` |
| `rounded-full` | `999px` |
| height (literal, no token) | `36px` |

| Typography/effect token | Resolved primitive value |
|---|---|
| `label/small` | `Noto Sans`, `14px`, weight `500`, line-height `20px`, letter-spacing `0px` |
| `shadow-sm` | `black/alpha-5`, offset `(0, 1)`, blur `2px`, spread `0px` |
| `black/alpha-0` | `#00000000` · alpha `0%` |
| `black/alpha-5` | `#0D000000` · alpha `5%` |

## V3 Metadata

```yaml
Theme system: V3
Widget: V3SmallButton
Category: button
Source: lib/widgets/v3/button/v3_small_button.dart
Preview: lib/widgets/v3/button/preview_v3_small_button.dart
Test: test/widgets/v3/button/v3_small_button_test.dart
Design source: Figma
Figma file: Wi Design System
Figma file key: mhUvPg9tOjlvQvEW6glQhJ
Figma node: "18:1764" (Size=Small group)
Semantic tokens:
  - button/primary
  - button/secondary
  - background/neutral
  - border/tertiary
  - border/slate
  - border/extension/info
  - border/extension/error
  - content/primary
  - content/white
  - content/neutral
  - content/neutral2
  - content/extension/navy
  - core/black
  - state/error
Dimension tokens:
  - space-0
  - space-2
  - space-6
  - space-16
  - space-20
  - rounded-full
Typography tokens:
  - label/small
Primitive effect/color tokens:
  - shadow-sm
  - black/alpha-0
  - black/alpha-5
```
