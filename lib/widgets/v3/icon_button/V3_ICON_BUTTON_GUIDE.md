# V3IconButton

`V3IconButton` คือปุ่มวงกลมสำหรับ action ที่ใช้ icon อย่างเดียว อ้างอิง Wi Design System Figma node `24:9246` และรับ accessible name ที่ localized แล้วจาก caller

## Usage

```dart
V3IconButton(
  icon: const V3LucideIcon(LucideIcons.search),
  semanticLabel: localizations.search,
  onPressed: onSearch,
)
```

## Public API

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `icon` | `Widget` | required | Icon slot; ใช้ `V3LucideIcon` เมื่อเป็น Lucide icon |
| `semanticLabel` | `String` | required | ชื่อ action ที่ localized แล้วสำหรับ assistive technology |
| `onPressed` | `VoidCallback?` | `null` | Callback; ค่า `null` ทำให้ปุ่ม disabled |
| `size` | `V3IconButtonSize` | `defaultSize` | Small 32, Medium 40, Large 48, Default 56 |
| `state` | `V3IconButtonState` | `defaultState` | บังคับ visual state สำหรับ preview/test หรือ disabled |
| `semanticHint` | `String?` | `null` | Localized semantic hint เพิ่มเติม |
| `tooltip` | `String?` | `null` | Localized tooltip |
| `focusNode` | `FocusNode?` | `null` | Focus control จาก caller |
| `autofocus` | `bool` | `false` | ขอ keyboard focus อัตโนมัติ |

## State behavior

- Default ใช้ `content/tertiary`; icon ใช้ `content/primary`
- Hover, pressed, focused และ forced `hoverActive` ใช้ `border/primary`
- Disabled ใช้ `background/neutral`; icon ใช้ `content/neutral2` และไม่เรียก callback
- ทุก state ใช้ `shadow-base` และ `rounded/full`

Figma ผูก Hover & Active กับ primitive `Blue/200` โดยตรง แต่ Theme V3 ไม่มี semantic background token ที่ผูกค่านี้ทั้งสอง theme จึงใช้ `border/primary`: Light ตรงกับ `Blue/200` และ Dark เปลี่ยนตาม semantic alias เป็น `Slate/700` เพื่อรักษา theme semantics โดยไม่ hardcode primitive ใน widget

`shadow-base` ยังไม่มี semantic shadow alias ใน Theme V3 จึงใช้ `V3PrimitiveShadows.base` ตาม effect style ที่ระบุใน design source โดยตรง

## Preview annotation

ข้อความชื่อขนาดใต้ปุ่มใน standalone preview อ้างอิง [Home · Exchange Button node `2:670`](https://www.figma.com/design/to0Ktb79J3DdxQMGuIBs3f/Home?node-id=2-670&t=rSEeRqTAUARv4vy8-4): ใช้ `V3Typography.labelMedium` (Noto Sans 16/24, weight 500, letter-spacing 0), สี `content/primary` และรักษา visual gap `V3Spacing.space8` จากขอบวงกลมถึงข้อความเท่ากันทุก size โดยชดเชยพื้นที่ accessibility target 48px ของ Small/Medium ข้อความนี้เป็น preview annotation ไม่ใช่ส่วนหนึ่งของ reusable `V3IconButton`

## Accessibility

- พื้นที่ interaction อย่างน้อย 48×48 logical pixels แม้ visual Small/Medium จะเล็กกว่า
- ปุ่มเป็น semantic node เดียว; icon ถูกตัดออกจาก semantics เพื่อไม่ให้ประกาศซ้ำ
- `semanticLabel` ต้องอธิบาย action ไม่ใช่ชื่อ glyph และต้อง localized โดย caller
- รองรับ hover, press, keyboard focus, activation และ disabled ผ่าน Material button behavior

## V3 Metadata

```yaml
Theme system: V3
Widget: V3IconButton
Category: icon_button
Source: lib/widgets/v3/icon_button/v3_icon_button.dart
Preview: lib/widgets/v3/icon_button/preview_v3_icon_button.dart
Test: test/widgets/v3/icon_button/v3_icon_button_test.dart
Semantic tokens:
  - content/tertiary
  - border/primary
  - background/neutral
  - content/primary
  - content/neutral2
```
