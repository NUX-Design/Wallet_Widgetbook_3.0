# V3 Navigation

Bottom navigation สำหรับ mobile app ตาม Figma component `Navigation` ขนาดอ้างอิง 343×96px ประกอบด้วย 4 selectable destinations และ Scan action ตรงกลางซึ่งเป็น primary action แยกจาก tab state

## Figma Source Of Truth

- Component set: [Navigation `110:5385`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=110-5385)
- Variants: Home `110:5384`, Card `110:5382`, Services `110:5383`, Menu `110:5381`
- Standard icon 24px, Scan 56px พร้อม icon 32px
- Active label ใช้ `label/tiny` Bold และ `content/primary`; inactive ใช้ `label/tiny` Medium และ `content/neutral`
- Surface ใช้ `background/white`, top border `border/primary` และ backdrop blur 15px
- Top border ใช้ความหนา 1px ตาม Figma และวาดเป็น foreground เหนือ backdrop blur เพื่อไม่ให้เส้นถูก blur กลบ
- Scan gradient ใช้ primitive `gold/400 → gold/800` ตาม Figma โดยตรง เพราะไม่มี semantic gradient token

## Usage

Icon slots accept any `Widget`. The pilot preview (`preview_v3_navigation.dart`) uses `V3LucideIcon` — see `V3_LUCIDE_ICON_GUIDE.md` for the adapter's API and the Figma-to-Lucide mapping for these five icons:

```dart
V3Navigation(
  destinations: [
    V3NavigationDestination(
      label: homeLabel,
      icon: const V3LucideIcon(LucideIcons.house),
      selectedIcon: const V3LucideIcon(LucideIcons.house, stroke: V3IconStroke.bold),
    ),
    V3NavigationDestination(
      label: cardLabel,
      icon: const V3LucideIcon(LucideIcons.creditCard),
      selectedIcon: const V3LucideIcon(LucideIcons.creditCard, stroke: V3IconStroke.bold),
    ),
    V3NavigationDestination(
      label: servicesLabel,
      icon: const V3LucideIcon(LucideIcons.layoutGrid),
      selectedIcon: const V3LucideIcon(LucideIcons.layoutGrid, stroke: V3IconStroke.bold),
    ),
    V3NavigationDestination(
      label: menuLabel,
      icon: const V3LucideIcon(LucideIcons.menu),
      selectedIcon: const V3LucideIcon(LucideIcons.menu, stroke: V3IconStroke.bold),
    ),
  ],
  selectedIndex: currentIndex,
  onDestinationSelected: setCurrentIndex,
  scanIcon: const V3LucideIcon(
    LucideIcons.scanLine,
    svgAsset: 'lib/assets/icons/v3/lucide/scan-line.svg',
  ),
  scanSemanticLabel: localizedScanLabel,
  onScanPressed: openScanner,
)
```

## Public API

| Property | Type | Description |
|---|---|---|
| `destinations` | `List<V3NavigationDestination>` | ต้องมี 4 รายการ; label ต้อง localized โดย caller |
| `selectedIndex` | `int` | active destination ช่วง 0–3 |
| `onDestinationSelected` | `ValueChanged<int>?` | callback ของ tab; `null` ปิด interaction ทุก destination |
| `scanIcon` | `Widget` | icon 32px ของ primary Scan action |
| `scanSemanticLabel` | `String` | localized accessibility label ของ Scan action |
| `onScanPressed` | `VoidCallback?` | callback ของ Scan; `null` ทำให้ action disabled |

`V3NavigationDestination` รับ `label`, `icon`, `selectedIcon` และ `semanticLabel` โดย `selectedIcon`/`semanticLabel` fallback เป็น `icon`/`label`

## Layout And Accessibility

- ความสูง bar 96px; standard icons 24px และ Scan button 56px ตาม Figma
- destination และ Scan action มี interactive target อย่างน้อย 48×48px
- รองรับ keyboard activation ผ่าน Material buttons และประกาศ selected/enabled semantics
- label จำกัดหนึ่งบรรทัดพร้อม ellipsis; caller ควรใช้คำสั้นและตรวจ localization จริง
- ใช้ semantic palette ผ่าน `V3ThemeScope` จึงรองรับ Light/Dark โดยไม่รับ mode จาก caller
- Figma shadow ของ surface ไม่มี primitive effect ที่ตรงกัน จึงเก็บค่าที่ตรวจจาก node `110:5385` ไว้เฉพาะใน component; Scan shadow ใช้ `gold/alpha-30`

Preview: `flutter run -t lib/widgets/v3/navigation/preview_v3_navigation.dart`

## Token Audit Values

ตารางนี้บันทึก resolved values จาก Theme V3 token source เพื่อให้ trace `Semantic → Primitive → Value` ได้โดยตรง หาก Figma token export เปลี่ยน ต้อง regenerate Theme V3 และอัปเดตตารางนี้พร้อมกัน

| Semantic token | Light primitive / value | Dark primitive / value |
|---|---|---|
| `background/white` | `White` · `#FFFFFF` | `Slate/800` · `#1E293B` |
| `border/primary` | `Blue/200` · `#DDE8FB` | `Slate/700` · `#334155` |
| `content/primary` | `Slate/900` · `#0F172A` | `White` · `#FFFFFF` |
| `content/neutral` | `Neutral/400` · `#A3A3A3` | `Neutral/400` · `#A3A3A3` |
| `content/white` | `White` · `#FFFFFF` | `White` · `#FFFFFF` |

| Dimension token | Primitive value |
|---|---:|
| `space-4` | `4px` |
| `space-8` | `8px` |
| `space-12` | `12px` |
| `space-24` | `24px` |
| `space-32` | `32px` |
| `space-56` | `56px` |
| `space-96` | `96px` |

| Typography/primitive token | Resolved primitive value |
|---|---|
| `label/tiny` | `Noto Sans`, `12px`, weight `500`, line-height `16px`, letter-spacing `0px` |
| `gold/400` | `#F5DDB0` |
| `gold/800` | `#C78814` |
| `gold/alpha-30` | `#4DDFAD51` · base `Gold/600 #DFAD51`, alpha `30%` |

## V3 Metadata

```yaml
Theme system: V3
Widget: V3Navigation
Category: navigation
Source: lib/widgets/v3/navigation/v3_navigation.dart
Preview: lib/widgets/v3/navigation/preview_v3_navigation.dart
Test: test/widgets/v3/navigation/v3_navigation_test.dart
Design source: Figma
Figma file: Wi Design System
Figma file key: mhUvPg9tOjlvQvEW6glQhJ
Figma nodes:
  - "110:5385"
  - "110:5384"
  - "110:5383"
  - "110:5382"
  - "110:5381"
Semantic tokens:
  - background/white
  - border/primary
  - content/primary
  - content/neutral
  - content/white
Dimension tokens:
  - space-4
  - space-8
  - space-12
  - space-24
  - space-32
  - space-56
  - space-96
Typography tokens:
  - label/tiny
Primitive tokens:
  - gold/400
  - gold/800
  - gold/alpha-30
```
