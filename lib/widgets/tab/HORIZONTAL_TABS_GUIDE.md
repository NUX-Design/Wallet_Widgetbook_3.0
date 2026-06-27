# Horizontal Tabs Widget Guide

## Overview
The `HorizontalTabs` widget is a theme-aware segmented tab control for switching content within the same screen. It is designed for compact category toggles such as `General / For You` or `History / Info / Setting`, and follows the project's design token system for both light and dark themes.

This widget is composed of:
- `HorizontalTabs`: the parent container that lays out and manages tab selection
- `HorizontalTabItem`: the data model for each tab label and badge state
- internal `_TabButton`: the visual tab button used per item

## Figma Source

### Main Component
- File: `NUX Widget Wallet Library`
- Component: `HorizontalTabs`
- Source link: [HorizontalTabs in Figma](https://www.figma.com/design/D7WVaC8n3foVLo6S3HuPn8/NUX-Widget-Wallet-Library?node-id=7754-33963&t=OjwKGnvnDzQ9tAWH-4)
- Node ID: `7754:33963`

### Sub Component
- File: `NUX Widget Wallet Library`
- Component: `TabButtonBase`
- Source link: [TabButtonBase in Figma](https://www.figma.com/design/D7WVaC8n3foVLo6S3HuPn8/NUX-Widget-Wallet-Library?node-id=7754-33970&t=OjwKGnvnDzQ9tAWH-4)
- Node ID: `7754:33970`

### Figma Variants
- `HorizontalTabs`
  - `qualitative=2`, `seleted=left`
  - `qualitative=2`, `seleted=right`
  - `qualitative=3`, `seleted=left`
  - `qualitative=3`, `seleted=center`
  - `qualitative=3`, `seleted=right`
- `TabButtonBase`
  - `state=primary`, `badge=on`
  - `state=primary`, `badge=off`
  - `state=secondary`, `badge=on`
  - `state=secondary`, `badge=off`

## Intended Usage
- ใช้สำหรับสลับ content ภายในหน้าจอเดียวกัน
- เหมาะกับการแบ่งหมวดข้อมูลระดับเดียวกัน เช่น history, info, settings
- ไม่ควรใช้เป็น primary navigation ของแอป
- label ควรสั้น กระชับ และอ่านได้ใน 1 บรรทัด
- badge ควรใช้เฉพาะเมื่อมี unread state หรือมีสิ่งใหม่ที่ต้องการเน้น

## Design Specifications

### Container
- **Height**: `44px`
- **Padding**: `4px` รอบ container
- **Gap Between Tabs**: `4px`
- **Border Radius**: `10px`
- **Background Token**: `fill/base/300`

### Tab Button
- **Height**: `36px`
- **Horizontal Padding**: `12px`
- **Vertical Padding**: `8px`
- **Border Radius**: `6px`
- **Layout**: แต่ละ tab ใช้ `Expanded` เพื่อกระจายความกว้างเท่ากัน

### Typography
- **Font**: `Noto Sans Thai`
- **Font Size**: `14px`
- **Font Weight**: `600`
- **Line Height**: `1.43`

### Badge
- **Size**: `7x7px`
- **Shape**: circle
- **Color Token**: `danger/500`
- **Spacing From Label**: `4px`

### Motion / Interaction
- **Press Scale**: `0.95`
- **Press Animation Duration**: `100ms`
- **State Transition Duration**: `200ms`
- **Transition Curve**: `Curves.easeInOut`

## Design Token Usage

### HorizontalTabs Container
- **Background**: `fill/base/300`

### Selected Tab
- **Background**: `primary/400`
- **Text**: `fill/contrast/600`

### Unselected Tab
- **Background**: `fill/base/300`
- **Text**: `text/base/500`

### Badge
- **Dot Color**: `danger/500`

## Public API

### HorizontalTabItem

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `label` | `String` | Yes | - | ข้อความบน tab |
| `showDot` | `bool` | No | `false` | แสดง badge dot สีแดง |

### HorizontalTabs

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `tabs` | `List<HorizontalTabItem>` | Yes | - | รายการ tabs ที่ต้องการแสดง |
| `selectedIndex` | `int` | Yes | - | index ของ tab ที่ active |
| `onTabChanged` | `ValueChanged<int>` | Yes | - | callback เมื่อผู้ใช้กดเปลี่ยน tab |

## Behaviour
- ผู้ใช้กด tab เพื่อเปลี่ยน selected index
- tab ที่ถูกเลือกจะเปลี่ยนพื้นหลังเป็น `primary/400`
- tab ที่ไม่ถูกเลือกใช้พื้นหลังเดียวกับ container
- badge สามารถแสดงได้ทั้ง selected และ unselected tab ตามข้อมูลที่ส่งเข้าไป
- รองรับ light/dark theme ผ่าน `Theme.of(context).brightness`
- label ถูกจำกัดไว้ที่ 1 บรรทัดด้วย `TextOverflow.ellipsis`

## Technical Implementation Details

### Current Flutter Structure
- `HorizontalTabs` เป็น `StatefulWidget`
- internal state `_pressedIndex` ใช้เก็บสถานะกดค้างชั่วคราวเพื่อทำ press animation
- selected state ถูกควบคุมจากภายนอกผ่าน `selectedIndex`
- ใช้ `GestureDetector` สำหรับ tap lifecycle:
  - `onTapDown`
  - `onTapUp`
  - `onTapCancel`
  - `onTap`

### Theming
- widget อ่าน theme ปัจจุบันจาก `Theme.of(context).brightness`
- map ค่า brightness เป็น `light` หรือ `dark`
- ดึงสีผ่าน `ThemeColors.get(brightnessKey, token)`

### Typography Implementation
- ใช้ `GoogleFonts.notoSansThai(...)`
- รองรับภาษาไทยได้เหมาะกับ design system ของ repo นี้

## Usage Examples

### Basic 2 Tabs
```dart
int selectedTab = 0;

HorizontalTabs(
  tabs: const [
    HorizontalTabItem(label: 'General'),
    HorizontalTabItem(label: 'For You'),
  ],
  selectedIndex: selectedTab,
  onTabChanged: (index) {
    setState(() => selectedTab = index);
  },
)
```

### 2 Tabs with Badge
```dart
HorizontalTabs(
  tabs: const [
    HorizontalTabItem(label: 'General', showDot: true),
    HorizontalTabItem(label: 'For You', showDot: true),
  ],
  selectedIndex: selectedTab,
  onTabChanged: (index) {
    setState(() => selectedTab = index);
  },
)
```

### 3 Tabs
```dart
int selectedInfoTab = 1;

HorizontalTabs(
  tabs: const [
    HorizontalTabItem(label: 'History'),
    HorizontalTabItem(label: 'Info'),
    HorizontalTabItem(label: 'Setting'),
  ],
  selectedIndex: selectedInfoTab,
  onTabChanged: (index) {
    setState(() => selectedInfoTab = index);
  },
)
```

## Preview

รัน preview file ได้ที่:

```bash
flutter run -t lib/widgets/tab/preview_horizontal_tabs.dart
```

ไฟล์ preview แสดงตัวอย่าง:
- 2 tabs พร้อม badge
- 3 tabs
- การสลับ light/dark theme
- interactive selection state

## File Structure
```text
lib/widgets/tab/
├── horizontal_tabs.dart              # Main widget implementation
├── preview_horizontal_tabs.dart      # Standalone preview for manual testing
└── HORIZONTAL_TABS_GUIDE.md          # This documentation
```

## Code Review Analysis

### ✅ Strengths
1. **Theme Token Compliance**: ใช้ `ThemeColors.get()` สำหรับสีหลักทั้งหมด
2. **Controlled Selection Model**: selected state ถูกควบคุมจาก parent ทำให้ integrate กับ state management ภายนอกได้ง่าย
3. **Reusable Data Model**: แยก `HorizontalTabItem` ทำให้ API อ่านง่าย
4. **Theme Awareness**: รองรับทั้ง light/dark mode
5. **Compact Interaction Feedback**: มี press animation ที่เบาและชัดเจน
6. **Text Safety**: ป้องกัน label ล้นด้วย `ellipsis`

### ⚠️ Implementation Notes
1. **No Semantics Layer Yet**: ปัจจุบันยังไม่มี explicit semantics label สำหรับ accessibility
2. **No Index Guard**: widget คาดหวังว่า `selectedIndex` จะอยู่ในช่วงของ `tabs`
3. **Figma Scope vs Flutter Scope**: Figma ระบุ use case หลักเป็น 2 หรือ 3 tabs แต่ Flutter implementation รองรับจำนวน tab มากกว่า 3 ได้ในทางเทคนิค
4. **Shadow Difference**: Figma component ของ selected tab มี shadow token ลักษณะ `shadow-sm` แต่ implementation ปัจจุบันไม่ได้ใส่ shadow
5. **Standalone Rule**: Figma ระบุว่า `TabButtonBase` ไม่ควรถูกใช้เดี่ยว ซึ่งใน Flutter ถูก enforce ทางโครงสร้างแล้วเพราะ `_TabButton` เป็น private widget

## Accessibility Notes
- ควรเพิ่ม semantics สำหรับ screen readers ในอนาคต เช่น:
  - ชื่อ tab
  - selected state
  - มี badge หรือไม่
- ควรตรวจสอบ contrast ของ `text/base/500` บน `fill/base/300` ในทุก theme ตาม baseline ของ design token system
- label ควรเป็นคำสั้นเพื่อหลีกเลี่ยงการ truncate มากเกินไป

## Recommendations
1. เพิ่ม assertion สำหรับ `tabs.isNotEmpty`
2. เพิ่ม assertion ให้ `selectedIndex` อยู่ในช่วงที่ถูกต้อง
3. พิจารณาเพิ่ม semantics สำหรับ accessibility
4. หากต้องการ parity กับ Figma มากขึ้น อาจเพิ่ม selected shadow เป็น design token
5. หากจะใช้กับ label ที่ยาวหรือจำนวน tab มาก ควรพิจารณา variant แบบ scrollable แยกอีก widget หนึ่งแทนการขยายความสามารถของตัวนี้

## Current Alignment Note
The current Flutter implementation aligns well with the key Figma behavior:
- selected vs unselected visual distinction
- 2-tab and 3-tab usage
- optional badge indicator
- compact segmented layout

Known implementation gap from Figma:
- selected tab shadow from Figma is not currently rendered in Flutter

