# V3 Mini Button Guide

## V3MiniButton

Button component สำหรับ Theme V3 ที่รองรับเฉพาะ Figma `Size=Mini` ครบ 3 variants × 4 states พร้อม optional left/right icons และ Light/Dark semantic colors ข้อความทั้งหมดมาจาก caller เพื่อรองรับ localization

### Design Source Of Truth

Figma nodes ต่อไปนี้เป็น SOT โดยตรงของแต่ละ variant/state:

| Variant | Default | Active | Disabled | Error |
|---|---|---|---|---|
| Primary | [`241:3475`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3475&t=uOGxt9VwxKIGvSsU-4) | [`241:3479`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3479&t=uOGxt9VwxKIGvSsU-4) | [`241:3483`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3483&t=uOGxt9VwxKIGvSsU-4) | [`241:3487`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3487&t=uOGxt9VwxKIGvSsU-4) |
| Outline | [`241:3851`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3851&t=uOGxt9VwxKIGvSsU-4) | [`241:3855`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3855&t=uOGxt9VwxKIGvSsU-4) | [`241:3859`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3859&t=uOGxt9VwxKIGvSsU-4) | [`241:3847`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3847&t=uOGxt9VwxKIGvSsU-4) |
| Ghost | [`241:3991`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3991&t=uOGxt9VwxKIGvSsU-4) | [`241:3995`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3995&t=uOGxt9VwxKIGvSsU-4) | [`241:3999`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-3999&t=uOGxt9VwxKIGvSsU-4) | [`241:4003`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=241-4003&t=uOGxt9VwxKIGvSsU-4) |

Icon slots accept any `Widget`. `preview_v3_mini_button.dart` uses `V3LucideIcon` (see `V3_LUCIDE_ICON_GUIDE.md`), which resolves its 12px size automatically from the button's own `IconTheme.merge` wrapper — no explicit `size` needed:

```dart
V3MiniButton(
  label: AppLocalizations.of(context)!.continueLabel,
  semanticLabel: AppLocalizations.of(context)!.continueLabel,
  variant: V3MiniButtonVariant.outline,
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
| `variant` | `V3MiniButtonVariant` | `primary` | `primary`, `outline` หรือ `ghost` |
| `state` | `V3MiniButtonState` | `defaultState` | `defaultState`, `active`, `disabled` หรือ `error` |
| `leadingIcon` | `Widget?` | `null` | icon ขนาด 12px นำหน้าข้อความ |
| `trailingIcon` | `Widget?` | `null` | icon ขนาด 12px ต่อท้ายข้อความ |
| `isLoading` | `bool` | `false` | แสดง progress และปิด interaction ชั่วคราว |
| `semanticLabel` | `String?` | `null` | label สำหรับ assistive technology; fallback เป็น `label` |
| `semanticHint` | `String?` | `null` | hint ที่ localized แล้วสำหรับ assistive technology |
| `tooltip` | `String?` | `null` | tooltip ที่ localized แล้วเมื่อจำเป็น |

### Figma Specification

| Variant | Height | Padding | Gap | Icon | Radius | Typography | Shadow |
|---|---:|---:|---:|---:|---|---|---|
| Primary | `space-24` | X `space-8`, Y `space-2` | `space-6` | `space-12` | `rounded-full` | `label/tiny` | none |
| Outline | `space-24` | X `space-8`, Y `space-2` | `space-6` | `space-12` | `rounded-full` | `label/tiny` | `shadow-sm` เฉพาะ Default/Active |
| Ghost | `space-16` | `space-0` | `space-6` | `space-12` | `rounded-full` | `label/tiny` + underline | none |

- Primary Active ใช้ `border/tertiary` ตาม semantic export
- Outline Active ใช้ `core/black` ที่ alpha 5% และ `content/neutral`
- Outline Error แยกสี content `state/error` กับ `border/extension/error` ตาม Figma
- Disabled ปิด callback แม้ caller ส่ง `onPressed`; Ghost Error ใช้ neutral content ตาม SOT
- keyboard focus ใช้ visual เดียวกับ Active เพื่อให้ focus มองเห็นได้
- component ใช้ `V3Typography`, `V3Spacing`, `V3Radii`, `V3PrimitiveColors` และ `V3PrimitiveShadows` โดยตรง จึงไม่มี visual metric, alpha หรือ effect ที่สร้างซ้ำด้วย magic number

### Icon Adoption Guidance

- `leadingIcon`/`trailingIcon` stay `Widget?` — `V3MiniButton`'s public API did not change to adopt Lucide; any icon widget still works.
- Prefer `V3LucideIcon(LucideIcons.*)` for new call sites so icon size/stroke/color stay governed by Theme V3 tokens and `IconTheme` instead of ad hoc `Icon(Icons.*)` literals.
- Do not pass an explicit `size` to `V3LucideIcon` inside `V3MiniButton` — the button's own `IconTheme.merge(data: IconThemeData(size: V3Spacing.space12))` wrapper already resolves the correct 12px (`V3IconSize.tiny`) size automatically.
- `stroke` defaults to `V3IconStroke.regular`; only pass an explicit `stroke` if a specific variant/state needs a different weight (no Mini Button state currently requires one).

### Accessibility

- Mini มี visual height 24px (Ghost 16px) ตาม SOT จึงควรวางใน parent hit-area อย่างน้อย 48×48px เมื่อใช้บน touch screen
- รองรับ keyboard focus/activation, active semantics และ localized semantic label/hint
- label เป็นหนึ่งบรรทัด; caller ควรส่งข้อความสั้นและ localized
- ตรวจ preview ได้ด้วย `flutter run -t lib/widgets/v3/button/preview_v3_mini_button.dart`; preview เริ่มต้นด้วย Light theme และใช้ toggle ด้านบนเพื่อสลับทั้งหน้าระหว่าง Light/Dark โดย component ทุก state อ่าน semantic colors จาก theme ที่เลือก

### Token Audit Values

ตารางนี้บันทึก resolved values จาก Theme V3 token source เพื่อให้ trace `Semantic → Primitive → Value` ได้โดยตรง หาก Figma token export เปลี่ยน ต้อง regenerate Theme V3 และอัปเดตตารางนี้พร้อมกัน

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
| `state/error` | `Red/600` · `#DC2626` | `Red/300` · `#FCA5A5` |

| Dimension token | Primitive value |
|---|---:|
| `space-0` | `0px` |
| `space-2` | `2px` |
| `space-6` | `6px` |
| `space-8` | `8px` |
| `space-12` | `12px` |
| `space-16` | `16px` |
| `space-24` | `24px` |
| `rounded-full` | `999px` |

| Typography/effect token | Resolved primitive value |
|---|---|
| `label/tiny` | `Noto Sans`, `12px`, weight `500`, line-height `16px`, letter-spacing `0px` |
| `shadow-sm` | `black/alpha-5`, offset `(0, 1)`, blur `2px`, spread `0px` |
| `black/alpha-0` | `#00000000` · alpha `0%` |
| `black/alpha-5` | `#0D000000` · alpha `5%` |

## V3 Metadata

```yaml
Theme system: V3
Widget: V3MiniButton
Category: button
Source: lib/widgets/v3/button/v3_mini_button.dart
Preview: lib/widgets/v3/button/preview_v3_mini_button.dart
Test: test/widgets/v3/button/v3_mini_button_test.dart
Design source: Figma
Figma file: Wi Design System
Figma file key: mhUvPg9tOjlvQvEW6glQhJ
Figma nodes:
  - "241:3475"
  - "241:3479"
  - "241:3483"
  - "241:3487"
  - "241:3851"
  - "241:3855"
  - "241:3859"
  - "241:3847"
  - "241:3991"
  - "241:3995"
  - "241:3999"
  - "241:4003"
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
  - space-8
  - space-12
  - space-16
  - space-24
  - rounded-full
Typography tokens:
  - label/tiny
Primitive effect/color tokens:
  - shadow-sm
  - black/alpha-0
  - black/alpha-5
```
