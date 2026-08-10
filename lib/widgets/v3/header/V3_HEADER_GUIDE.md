# V3 Header

Page-level Header ตาม Figma component set `Header` สำหรับใช้เป็น `Scaffold.appBar` โดยตรง รองรับ navigation action, title, subtitle และ contextual actions ที่ caller เลือกเปิดเฉพาะ slot ที่ต้องใช้

## Figma Source Of Truth

- Component set: [`Header` `372:297`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=372-297)
- Full variant: [`568:1322`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=568-1322)
- Full variant: leading action + title + subtitle + trailing action, ขนาดอ้างอิง 375×124px
- Component padding ใช้ vertical 12px และ horizontal 16px; runtime ยังใช้ `SafeArea`/`MediaQuery.padding.top` เพิ่มเหนือ component เมื่อวางใน `Scaffold.appBar`
- Visual icon 24px; action target 48×48px
- Leading-to-content gap 16px; title-to-subtitle gap 8px
- Title ใช้ `heading/small`; subtitle ใช้ `paragraph/small`

Figma node และไฟล์ handoff bind เส้นล่างกับ `background/blue` แม้ component description จะกล่าวถึง `border/primary` จึงยึด verified node binding `background/blue` เป็น implementation source สำหรับรอบนี้

## Usage

```dart
Scaffold(
  appBar: V3Header(
    title: localizedTitle,
    subtitle: localizedSubtitle,
    leadingAction: V3HeaderAction(
      icon: const V3LucideIcon(
        LucideIcons.arrowLeft,
        stroke: V3IconStroke.light,
      ),
      semanticLabel: localizedBackLabel,
      onPressed: Navigator.of(context).pop,
    ),
    trailingAction: V3HeaderAction(
      icon: const V3LucideIcon(
        LucideIcons.info,
        stroke: V3IconStroke.light,
      ),
      semanticLabel: localizedInfoLabel,
      onPressed: showInformation,
    ),
    topTrailingAction: V3HeaderAction(
      icon: const V3LucideIcon(
        LucideIcons.x,
        stroke: V3IconStroke.light,
      ),
      semanticLabel: localizedCloseLabel,
      onPressed: close,
    ),
  ),
)
```

ทุก action slot เป็น nullable และ icon-agnostic ตัวอย่างหน้าที่ไม่ต้องมีปุ่มปิดสามารถละ `topTrailingAction` ได้โดยไม่ต้องส่ง placeholder:

```dart
V3Header(
  title: localizedTitle,
  leadingAction: canNavigateBack
      ? V3HeaderAction(
          icon: const V3LucideIcon(LucideIcons.arrowLeft),
          semanticLabel: localizedBackLabel,
          onPressed: Navigator.of(context).pop,
        )
      : null,
  trailingAction: canShowHelp
      ? V3HeaderAction(
          icon: customHelpIcon,
          semanticLabel: localizedHelpLabel,
          onPressed: showHelp,
        )
      : null,
)
```

## Public API

### `V3Header`

| Property | Type | Description |
|---|---|---|
| `title` | `String?` | Localized page title; `null` ซ่อน title area |
| `subtitle` | `String?` | Localized supporting text; ต้องมี `title` |
| `leadingAction` | `V3HeaderAction?` | Optional leading navigation action |
| `trailingAction` | `V3HeaderAction?` | Optional contextual action |
| `topTrailingAction` | `V3HeaderAction?` | Optional action ฝั่งขวาของ top action row |
| `preferredSize` | `Size` | ความสูง top padding + content + bottom padding โดยไม่รวม device top safe area; `Scaffold` จะบวก device inset ให้ |

### `V3HeaderAction`

| Property | Type | Description |
|---|---|---|
| `icon` | `Widget` | Visual icon; ปรับสีและขนาดผ่าน `IconTheme` |
| `semanticLabel` | `String` | Localized accessibility label |
| `onPressed` | `VoidCallback?` | Callback; `null` แสดง disabled semantics |
| `semanticHint` | `String?` | Optional localized semantics hint |
| `tooltip` | `String?` | Optional localized tooltip |

## Variants And Behavior

- รองรับ 10 composition variants ที่พบใน Figma handoff ผ่าน nullable properties
- implement `PreferredSizeWidget` และส่งเข้า `Scaffold.appBar` ได้โดยตรง
- top safe area detect จาก `MediaQuery.padding.top` ผ่าน `SafeArea` จึงรองรับ status bar, notch และ Dynamic Island ของแต่ละอุปกรณ์โดยไม่ hardcode
- ความสูง component ของ full variant คือ `preferredSize.height = 124`; เมื่อใช้เป็น `Scaffold.appBar` ความสูงบนหน้าจอคือ `MediaQuery.padding.top + 124px`
- หากไม่มี title จะไม่อนุญาต subtitle
- ต้องมีอย่างน้อย title หรือ action หนึ่งตัว
- action visual 24px แต่มี touch target 48×48px
- `leadingAction` และ `topTrailingAction` อยู่ใน top action row เดียวกัน
- `trailingAction` อยู่ข้าง title ตามตำแหน่ง contextual action เดิม
- action slot ทั้งสามเป็น optional: ส่ง `null` เพื่อซ่อนตามบริบทของหน้าจอ
- caller เปลี่ยน glyph ได้โดยส่ง `Widget` ใดก็ได้ผ่าน `V3HeaderAction.icon`
- action กดได้เมื่อ `onPressed` ไม่เป็น `null`; หากเป็น `null` จะแสดง disabled semantics
- component ไม่ hardcode copy หรือ icon library; caller เป็นเจ้าของ localized text และ icon
- semantic colors เปลี่ยนตาม Light/Dark ผ่าน `V3ThemeScope`
- ข้อความขยายความสูงตาม text scaling แทนการตัดหรือบังคับ fixed height

## Token Audit

| Token | Usage |
|---|---|
| `background/primary` | Header surface |
| `background/blue` | Bottom divider ตาม verified Figma binding |
| `content/primary` | Title, subtitle และ icon |
| `heading/small` | Title typography |
| `paragraph/small` | Subtitle typography |
| `shadow/sm` | Figma `shadow-sm` |
| `space-8` | Title-to-subtitle gap |
| `space-12` | Top และ bottom component padding/action padding |
| `space-16` | Horizontal padding/leading-to-content gap |
| `space-24` | Visual icon |

Preview:

```bash
flutter run -t lib/widgets/v3/header/preview_v3_header.dart
```

Preview ใช้ `background/primary`, สลับ Light/Dark แบบเต็มความกว้าง และแสดง `Action: …` เมื่อกด action ของ Header เท่านั้น โดยไม่ใส่ component อื่นในหน้าจอเพื่อรักษาขอบเขตของ preview ให้ชัดเจน รูปแบบ feedback นี้เป็น preview-only; reusable widget ส่ง event ผ่าน callback และไม่สร้างข้อความหรือ navigation side effect เอง

## V3 Metadata

```yaml
Theme system: V3
Widget: V3Header
Category: header
Source: lib/widgets/v3/header/v3_header.dart
Preview: lib/widgets/v3/header/preview_v3_header.dart
Test: test/widgets/v3/header/v3_header_test.dart
Design source: Figma
Figma file: Wi Design System
Figma file key: mhUvPg9tOjlvQvEW6glQhJ
Figma nodes:
  - "372:297"
  - "568:1322"
Semantic tokens:
  - background/primary
  - background/blue
  - content/primary
Dimension tokens:
  - space-8
  - space-12
  - space-16
  - space-24
Typography tokens:
  - heading/small
  - paragraph/small
Effect tokens:
  - shadow/sm
```
