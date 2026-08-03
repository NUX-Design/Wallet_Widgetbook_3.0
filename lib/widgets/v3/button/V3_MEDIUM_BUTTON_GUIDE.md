# V3 Medium Button Guide

## V3MediumButton

Button component สำหรับ Theme V3 ที่รองรับเฉพาะ Figma `Size=Medium` ครบ 3 variants × 4 states พร้อม optional left/right icons และ Light/Dark semantic colors ข้อความทั้งหมดมาจาก caller เพื่อรองรับ localization

`V3MediumButton` แชร์ Figma component set node เดียวกับสมาชิกอื่นในตระกูล Button (`18:1764`, `Size=Medium`) — ดู `button-_base.json` และ `button.md` สำหรับข้อมูล cross-size ทั้งหมด

### Design Source Of Truth

- **Figma component set:** [`18:1764`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=18-1764) (`Size=Medium`, ทุก hierarchy × state)
- **uSpec base JSON:** `lib/widgets/v3/button/button-_base.json` (`_meta.componentSlug: "button"`, ครอบคลุมทั้ง 4 sizes)
- **Generated component doc:** `lib/widgets/v3/button/button.md` — Structure/Color/Voice ของ Medium อยู่ในคอลัมน์ "medium" ของทุกตาราง
- Figma `State` variant axis ของ Medium เก็บ `Default/Active/Disabled/Error` ครบทั้ง 4 ค่า (re-extract ล่าสุดวันที่ `2026-08-03`, node `18:1764`, 192 variants) — ยืนยันตรงกับที่ `V3MiniButton` ใช้อยู่แล้ว ไม่ใช่การอนุมานจาก "focus/active เท่ากันทุก size" อีกต่อไป: สี Primary Active (`#456cb9` = `border/tertiary`) ตรวจสอบแล้วว่าเหมือนกันทุก size จริงจาก `colorWalk`

Icon slots accept any `Widget`. `preview_v3_medium_button.dart` ใช้ `V3LucideIcon` (ดู `V3_LUCIDE_ICON_GUIDE.md`) ที่ resolve ขนาด 16px จาก `IconTheme.merge` wrapper ของปุ่มโดยอัตโนมัติ — ไม่ต้องส่ง `size` เอง:

```dart
V3MediumButton(
  label: AppLocalizations.of(context)!.continueLabel,
  semanticLabel: AppLocalizations.of(context)!.continueLabel,
  variant: V3MediumButtonVariant.outline,
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
| `variant` | `V3MediumButtonVariant` | `primary` | `primary`, `outline` หรือ `ghost` |
| `state` | `V3MediumButtonState` | `defaultState` | `defaultState`, `active`, `disabled` หรือ `error` |
| `leadingIcon` | `Widget?` | `null` | icon ขนาด 16px นำหน้าข้อความ |
| `trailingIcon` | `Widget?` | `null` | icon ขนาด 16px ต่อท้ายข้อความ |
| `isLoading` | `bool` | `false` | แสดง progress และปิด interaction ชั่วคราว |
| `semanticLabel` | `String?` | `null` | label สำหรับ assistive technology; fallback เป็น `label` |
| `semanticHint` | `String?` | `null` | hint ที่ localized แล้วสำหรับ assistive technology |
| `tooltip` | `String?` | `null` | tooltip ที่ localized แล้วเมื่อจำเป็น |

### Figma Specification

| Variant | Height | Padding | Gap | Icon | Radius | Typography | Shadow |
|---|---:|---:|---:|---:|---|---|---|
| Primary | `space-40` | X `space-24`, Y `space-8` | `space-8` | `space-16` | `rounded-full` | `label/small` | none |
| Outline | `space-40` | X `space-24`, Y `space-8` | `space-8` | `space-16` | `rounded-full` | `label/small` | `shadow-sm` เฉพาะ Default/Active |
| Ghost | `space-20` | `space-0` | `space-8` | `space-16` | `rounded-full` | `label/small` + underline | none |

- ค่าทั้งหมดวัดจาก `button-_base.json`'s 192-variant walk (`Size=Medium` group, 48 variants: 3 hierarchies × 4 states × 4 icon-visibility combinations) เทียบตรงกับ `button.md` Structure section
- Medium เป็น size เดียวในตระกูลที่ height (`40px`) ตรงกับ `V3Spacing.space40` พอดี จึงไม่ต้องใช้ literal
- Color/border logic สืบทอดจาก `V3MiniButton` ตาม `button.md`'s "Color tokens are independent of size" — Primary Active ใช้ `border/tertiary`, Outline Active ใช้ `core/black` alpha 5% + `content/neutral`, Outline Error แยกสี content `state/error` กับ border `border/extension/error`
- Disabled ปิด callback แม้ caller ส่ง `onPressed`; keyboard focus ใช้ visual เดียวกับ Active
- component ใช้ `V3Typography`, `V3Spacing`, `V3Radii`, `V3PrimitiveColors` และ `V3PrimitiveShadows` โดยตรง

### Accessibility

- Medium มี visual height 40px (Ghost 20px) ตาม SOT
- รองรับ keyboard focus/activation, active semantics และ localized semantic label/hint
- label เป็นหนึ่งบรรทัด; caller ควรส่งข้อความสั้นและ localized
- ตรวจ preview ได้ด้วย `flutter run -t lib/widgets/v3/button/preview_v3_medium_button.dart`

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
| `space-8` | `8px` |
| `space-16` | `16px` |
| `space-20` | `20px` |
| `space-24` | `24px` |
| `space-40` | `40px` |
| `rounded-full` | `999px` |

| Typography/effect token | Resolved primitive value |
|---|---|
| `label/small` | `Noto Sans`, `14px`, weight `500`, line-height `20px`, letter-spacing `0px` |
| `shadow-sm` | `black/alpha-5`, offset `(0, 1)`, blur `2px`, spread `0px` |
| `black/alpha-0` | `#00000000` · alpha `0%` |
| `black/alpha-5` | `#0D000000` · alpha `5%` |

## V3 Metadata

```yaml
Theme system: V3
Widget: V3MediumButton
Category: button
Source: lib/widgets/v3/button/v3_medium_button.dart
Preview: lib/widgets/v3/button/preview_v3_medium_button.dart
Test: test/widgets/v3/button/v3_medium_button_test.dart
Design source: Figma
Figma file: Wi Design System
Figma file key: mhUvPg9tOjlvQvEW6glQhJ
Figma node: "18:1764" (Size=Medium group)
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
  - space-8
  - space-16
  - space-20
  - space-24
  - space-40
  - rounded-full
Typography tokens:
  - label/small
Primitive effect/color tokens:
  - shadow-sm
  - black/alpha-0
  - black/alpha-5
```
