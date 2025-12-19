# FullAmountInput Widget Specification

## Overview
`FullAmountInput` เป็น custom Flutter widget สำหรับรับ input จำนวนเงิน พร้อม validation และ visual feedback แบบ real-time รองรับทั้ง dark และ light mode

https://www.figma.com/design/D7WVaC8n3foVLo6S3HuPn8/New-Wi-Wallet-2.0?node-id=7066-6048&t=sYCnD6dsF9QpTyn1-4

## Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.0.0
  google_fonts: ^6.0.0
```

## Required Assets
- `lib/assets/images/cancel-circle.svg` - ไอคอนสำหรับปุ่ม clear

## Theme System Requirements
Widget ต้องการ `ThemeColors` helper class ที่รองรับ color tokens ดังนี้:

### Dark Mode Colors
- `fill/base/300`: #1A1A1A (background)
- `stroke/base/200`: #4A4A4A (border default)
- `stroke/base/600`: #787878 (clear icon)
- `text/base/400`: #ffffff73 (placeholder, info text)
- `text/base/600`: #FFFFFF (active text, prefix)
- `text/base/danger`: สีแสดง error
- `text/base/success`: สีแสดง success
- `primary/400`: สี border เมื่อ success + focus

### Light Mode Colors
- `fill/base/300`: #F5F5F5 (background)
- `stroke/base/200`: border default
- `stroke/base/600`: clear icon
- `text/base/400`: placeholder, info text
- `text/base/600`: active text, prefix
- `text/base/danger`: สีแสดง error
- `text/base/success`: สีแสดง success
- `primary/400`: สี border เมื่อ success + focus

## Properties

### Input Parameters
| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `controller` | `TextEditingController?` | No | `null` | Controller สำหรับควบคุม TextField |
| `initialValue` | `String?` | No | `''` | ค่าเริ่มต้นของ input |
| `onChanged` | `ValueChanged<String>?` | No | `null` | Callback เมื่อค่าใน input เปลี่ยน |
| `infoText` | `String` | No | `'ท่านต้องฝากเงินอย่างน้อย 100 THB'` | ข้อความแสดงด้านล่าง input |
| `isDisabled` | `bool` | No | `false` | สถานะ disabled state ของ input |

## Features

### 1. Currency Prefix (฿)
- แสดงสัญลักษณ์ ฿ ด้านหน้า input เสมอ
- เปลี่ยนสีเป็น `text/base/600` เมื่อ:
  - มีการกรอกข้อมูล หรือ
  - Input อยู่ใน focus state

### 2. Clear Button
- แสดงไอคอน clear (X) เมื่อมีข้อความใน input
- กดเพื่อลบข้อความทั้งหมด
- ซ่อนอัตโนมัติเมื่อไม่มีข้อความ

### 3. Input Validation
- รับเฉพาะตัวเลขและจุดทศนิยม (0-9 และ .)
- Keyboard type: `numberWithOptions(decimal: true)`

### 4. State Management

#### Default State
- Border: `stroke/base/200`
- Background: `fill/base/300`
- Prefix ฿: `text/base/400`
- Placeholder: `text/base/400`
- Info text: `text/base/400`

#### Focus State (คลิกที่ input)
- Prefix ฿: `text/base/600`
- Cursor: `text/base/600`

#### Error State (value < 100)
- เงื่อนไข: มีการ focus หรือกรอกค่า และค่า < 100
- Border: `text/base/danger`
- Info text: `text/base/danger`

#### Success State (value >= 100)
- เงื่อนไข: กรอกค่า >= 100
- Border (เมื่อ focus): `primary/400`
- Border (เมื่อไม่ focus): `stroke/base/200`
- Info text: `text/base/success`
- Prefix ฿: `text/base/600`
- Input text: `text/base/600`

#### Disabled State
- เงื่อนไข: widget ถูก disabled ด้วย parent
- Input: ไม่สามารถกรอกข้อมูลได้
- Border: `stroke/base/200`
- Background: `fill/base/300`
- Prefix ฿: `text/base/400` (opacity ลดลง)
- Placeholder: ไม่แสดง
- Clear button: ซ่อน

## Usage Examples

### Basic Usage
```dart
FullAmountInput(
  onChanged: (value) {
    print('Amount: $value');
  },
)
```

### With Controller
```dart
final controller = TextEditingController();

FullAmountInput(
  controller: controller,
  onChanged: (value) {
    print('Amount: $value');
  },
)
```

### With Initial Value
```dart
FullAmountInput(
  initialValue: '500',
  onChanged: (value) {
    print('Amount: $value');
  },
)
```

### Custom Info Text
```dart
FullAmountInput(
  infoText: 'จำนวนเงินขั้นต่ำ 50 THB',
  onChanged: (value) {
    print('Amount: $value');
  },
)
```

## Dimensions
- Input height: 44px
- Input padding: 12px
- Border radius: 8px
- Border width: 1px
- Gap between input and info text: 8px
- Info text height: 12px

## Typography
- Font family: Noto Sans Thai (Google Fonts)
- Input text size: 15px (line height: 1.33)
- Info text size: 10px (line height: 1.2, weight: 600)

## Behavior Flow

### User Interaction Flow
1. **Initial State**: Input ว่าง, border และ text เป็นสีปกติ
2. **Click Input**: Prefix ฿ เปลี่ยนเป็นสี `text/base/600`
3. **Type < 100**: Border และ info text เป็นสี danger
4. **Type >= 100**: Border เป็นสี `primary/400`, info text เป็นสี success
5. **Click Outside**: Border กลับเป็นสีปกติ (ถ้า value >= 100), info text ยังคงเป็นสี success

## Integration Checklist
- [ ] ติดตั้ง dependencies: `flutter_svg`, `google_fonts`
- [ ] เพิ่ม cancel-circle.svg ใน assets
- [ ] สร้าง ThemeColors helper class พร้อม color tokens
- [ ] กำหนด theme colors สำหรับ dark และ light mode
- [ ] Import FullAmountInput widget
- [ ] ทดสอบการทำงานใน dark/light mode

## Notes
- Widget รองรับ responsive width (ใช้ `double.infinity`)
- การ validate ทำงานแบบ real-time
- รองรับ Thai language ด้วย Noto Sans Thai font
- Memory management: dispose controllers และ listeners อัตโนมัติ
