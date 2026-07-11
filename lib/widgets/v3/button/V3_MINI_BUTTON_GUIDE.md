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

```dart
V3MiniButton(
  label: AppLocalizations.of(context)!.continueLabel,
  semanticLabel: AppLocalizations.of(context)!.continueLabel,
  variant: V3MiniButtonVariant.outline,
  leadingIcon: const Icon(Icons.arrow_forward),
  trailingIcon: const Icon(Icons.chevron_right),
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

| Variant | Height | Padding X | Gap | Icon | Typography |
|---|---:|---:|---:|---:|---|
| Primary / Outline | 24 | 8 | 6 | 12 | Noto Sans 12/16, 500 |
| Ghost | 16 | 0 | 6 | 12 | Noto Sans 12/16, 500, underline |

- Primary Active ใช้ `border/tertiary` ตาม semantic export
- Outline Active ใช้ `core/black` ที่ alpha 5% และ `content/neutral`
- Outline Error แยกสี content `state/error` กับ `border/extension/error` ตาม Figma
- Disabled ปิด callback แม้ caller ส่ง `onPressed`; Ghost Error ใช้ neutral content ตาม SOT
- keyboard focus ใช้ visual เดียวกับ Active เพื่อให้ focus มองเห็นได้

### Accessibility

- Mini มี visual height 24px (Ghost 16px) ตาม SOT จึงควรวางใน parent hit-area อย่างน้อย 48×48px เมื่อใช้บน touch screen
- รองรับ keyboard focus/activation, active semantics และ localized semantic label/hint
- label เป็นหนึ่งบรรทัด; caller ควรส่งข้อความสั้นและ localized
- ตรวจ preview ได้ด้วย `flutter run -t lib/widgets/v3/button/preview_v3_mini_button.dart`; preview เริ่มต้นด้วย Light theme และใช้ toggle ด้านบนเพื่อสลับทั้งหน้าระหว่าง Light/Dark โดย component ทุก state อ่าน semantic colors จาก theme ที่เลือก

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
```
