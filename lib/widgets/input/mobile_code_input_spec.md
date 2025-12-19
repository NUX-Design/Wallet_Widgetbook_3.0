# MobileCodeInput Widget Specification

## Overview
`MobileCodeInput` เป็น custom Flutter widget สำหรับรับ input เบอร์มือถือ พร้อม country code selector และ visual feedback แบบ real-time รองรับทั้ง dark และ light mode

https://www.figma.com/design/D7WVaC8n3foVLo6S3HuPn8/New-Wi-Wallet-2.0?node-id=7066-6083&t=sYCnD6dsF9QpTyn1-4

## Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.0.0
  google_fonts: ^6.0.0
```

## Required Assets
- `lib/assets/images/flag_th.svg` - ธงชาติไทย (หรือธงประเทศอื่นๆ)
- `lib/assets/images/arrow-down-01.svg` - ไอคอน dropdown
- `lib/assets/images/cancel-circle.svg` - ไอคอนสำหรับปุ่ม clear

## Theme System Requirements
Widget ต้องการ `ThemeColors` helper class ที่รองรับ color tokens ดังนี้:

### Dark Mode Colors
- `fill/base/300`: #1A1A1A (background)
- `stroke/base/200`: #4A4A4A (border default)
- `stroke/base/600`: #787878 (clear icon)
- `text/base/400`: #FFFFFF · 45% (placeholder, digit counter)
- `text/base/600`: #FFFFFF (active text, country code)
- `text/base/danger`: สี border และ error message เมื่อ error state
- `primary/400`: สี border เมื่อ focus

### Light Mode Colors
- `fill/base/300`: #F5F5F5 (background)
- `stroke/base/200`: border default
- `stroke/base/600`: clear icon
- `text/base/400`: #0F0F0F · 45% (placeholder, digit counter)
- `text/base/600`: active text, country code
- `text/base/danger`: สี border และ error message เมื่อ error state
- `primary/400`: สี border เมื่อ focus

## Properties

### Input Parameters
| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `controller` | `TextEditingController?` | No | `null` | Controller สำหรับควบคุม TextField |
| `initialValue` | `String?` | No | `''` | ค่าเริ่มต้นของ input |
| `onChanged` | `ValueChanged<String>?` | No | `null` | Callback เมื่อค่าใน input เปลี่ยน |
| `countryCode` | `String` | No | `'+66'` | รหัสประเทศ |
| `flagAsset` | `String` | No | `'lib/assets/images/flag_th.svg'` | ไฟล์ธงชาติ |
| `onCountryCodeTap` | `VoidCallback?` | No | `null` | Callback เมื่อกดที่ country code selector |
| `maxLength` | `int` | No | `10` | จำนวนตัวเลขสูงสุดที่สามารถกรอกได้ |
| `errorText` | `String?` | No | `null` | ข้อความ error ที่จะแสดงใต้ input (ถ้ามี) |
| `hasError` | `bool` | No | `false` | สถานะ error ของ input |

## Features

### 1. Country Code Selector
- แสดงธงชาติ (32×24px)
- แสดงรหัสประเทศ (เช่น +66)
- แสดงไอคอน arrow-down (24×24px)
- กดเพื่อเปิด dropdown เลือกประเทศ
- Gap 4px ระหว่าง flag และ code

### 2. Clear Button
- แสดงไอคอน cancel-circle เมื่อมีข้อความใน input
- กดเพื่อลบข้อความทั้งหมด
- ซ่อนอัตโนมัติเมื่อไม่มีข้อความ
- ขนาด 16×16px (container)
- Design: Circle พร้อม X symbol (ขนาด 14.33px ในวงกลม 16px)
- สี: `stroke/base/600` (#787878)
- Stroke width: 1px
- ไฟล์: `lib/assets/images/cancel-circle.svg`

### 3. Input Field
- รับเฉพาะตัวเลข (0-9)
- จำกัดจำนวนตัวเลขตาม `maxLength` (default: 10)
- Placeholder: "เบอร์มือถือ"
- Font: Noto Sans Thai, 15px, line-height 1.33
- Keyboard type: phone

### 4. Digit Counter
- แสดงจำนวนตัวเลขที่กรอก/จำนวนสูงสุด (เช่น "0/10")
- อยู่ด้านล่าง input ชิดขวา
- Gap 4px จาก input
- Font: Noto Sans Thai, 15px, line-height 1.33
- สี: `text/base/400`
- อัปเดตแบบ real-time ตามการกรอก
- แสดงทั้งใน normal state และ error state

### 5. Error Message
- แสดงเมื่อ `errorText` ไม่เป็น null และ `hasError` เป็น true
- อยู่ด้านล่าง input ชิดซ้าย
- Gap 4px จาก input
- Font: Noto Sans Thai, 10px, 600 weight (semi-bold), line-height 1.2
  - สี: `text/base/danger` (#FF2729)
- แสดงพร้อมกับ digit counter (error message ซ้าย, counter ขวา)

### 6. State Management

#### Default State
- Border: `stroke/base/200`
- Background: `fill/base/300`
- Country code: `text/base/600`
- Placeholder: `text/base/400`
- Clear button: ซ่อน

#### Focus State (คลิกที่ input)
- Border: `primary/400`
- Cursor: `text/base/600`

#### Has Text State (กรอกข้อความ)
- Input text: `text/base/600`
- Clear button: แสดง

#### Error State (validation ผิดพลาด)
- Border: `text/base/danger`
- Error message: แสดงใต้ input ชิดซ้าย
- Digit counter: แสดงใต้ input ชิดขวา (ยังคงแสดงอยู่)
- Layout: Row ที่มี error message (ซ้าย) และ digit counter (ขวา)
- เกิดขึ้นเมื่อ `hasError` เป็น true และ `errorText` ไม่เป็น null
- ตัวอย่างกรณีที่เกิด error:
  - กรอกเบอร์มือถือไม่ครบตาม format
  - กรอกเบอร์มือถือที่ไม่ถูกต้อง
  - กดปุ่ม submit แล้ว validation ไม่ผ่าน

## Usage Examples

### Basic Usage
```dart
MobileCodeInput(
  onChanged: (value) {
    print('Phone: $value');
  },
)
```

### With Controller
```dart
final controller = TextEditingController();

MobileCodeInput(
  controller: controller,
  onChanged: (value) {
    print('Phone: $value');
  },
)
```

### With Country Code Selector
```dart
MobileCodeInput(
  countryCode: '+66',
  flagAsset: 'lib/assets/images/flag_th.svg',
  onCountryCodeTap: () {
    // Show country selector dialog
  },
  onChanged: (value) {
    print('Phone: $value');
  },
)
```

### With Initial Value
```dart
MobileCodeInput(
  initialValue: '0812345678',
  onChanged: (value) {
    print('Phone: $value');
  },
)
```

### With Custom Max Length
```dart
MobileCodeInput(
  maxLength: 9,  // สำหรับประเทศที่มีเบอร์ 9 หลัก
  countryCode: '+1',
  flagAsset: 'lib/assets/images/flag_us.svg',
  onChanged: (value) {
    print('Phone: $value');
  },
)
```

### With Error State
```dart
MobileCodeInput(
  hasError: true,
  errorText: 'เบอร์มือถือไม่ถูกต้อง',
  onChanged: (value) {
    print('Phone: $value');
  },
)
```

### With Validation on Submit
```dart
final controller = TextEditingController();
String? errorText;
bool hasError = false;

MobileCodeInput(
  controller: controller,
  hasError: hasError,
  errorText: errorText,
  onChanged: (value) {
    // Clear error when user types
    setState(() {
      hasError = false;
      errorText = null;
    });
  },
)

// On submit button
void onSubmit() {
  final phone = controller.text;
  if (phone.length < 10) {
    setState(() {
      hasError = true;
      errorText = 'กรุณากรอกเบอร์มือถือให้ครบ 10 หลัก';
    });
  } else if (!isValidPhone(phone)) {
    setState(() {
      hasError = true;
      errorText = 'เบอร์มือถือไม่ถูกต้อง';
    });
  }
}
```

## Dimensions
- Input height: 48px
- Input padding: 12px
- Border radius: 12px
- Border width: 1px
- Gap between country code and input: 8px
- Gap between flag and code: 4px
- Gap between input and counter: 4px
- Flag size: 32×24px
- Arrow icon size: 24×24px
- Clear icon size: 16×16px
- Total widget height: 72px (48px input + 4px gap + 20px counter/error message)

## Typography
- Font family: Noto Sans Thai (Google Fonts)
- Input text size: 15px (line height: 1.33)
- Country code size: 15px (line height: 1.33)
- Digit counter size: 15px (line height: 1.33)
- Error message size: 15px (line height: 1.33)

## Behavior Flow

### User Interaction Flow
1. **Initial State**: Input ว่าง, border และ text เป็นสีปกติ, ไม่มี clear button, counter แสดง "0/10"
2. **Click Country Code**: เรียก `onCountryCodeTap` callback เพื่อแสดง country selector
3. **Click Input**: Border เปลี่ยนเป็นสี `primary/400`
4. **Type Number**: Text เปลี่ยนเป็นสี `text/base/600`, clear button ปรากฏ, counter อัปเดต (เช่น "5/10")
5. **Reach Max Length**: ไม่สามารถกรอกเพิ่มได้, counter แสดง "10/10"
6. **Click Clear**: ข้อความถูกลบ, clear button หายไป, counter กลับเป็น "0/10", เรียก `onChanged('')`
7. **Click Outside**: Border กลับเป็นสีปกติ
8. **Submit with Invalid Data**: Parent widget set `hasError = true` และ `errorText`, border เปลี่ยนเป็น `text/base/danger`, error message แสดงใต้ input ชิดซ้าย, digit counter ยังคงแสดงชิดขวา
9. **Type After Error**: Parent widget ควร clear error state (`hasError = false`, `errorText = null`), border กลับเป็นสีปกติ, error message หายไป, digit counter ยังคงแสดงอยู่

### Error State Behavior
- Error state ถูกควบคุมโดย parent widget ผ่าน `hasError` และ `errorText` properties
- เมื่ออยู่ใน error state:
  - Border เปลี่ยนเป็นสี `text/base/danger`
  - Error message แสดงใต้ input ชิดซ้าย
  - Digit counter ยังคงแสดงใต้ input ชิดขวา
  - Layout: Row ที่มี error message (flex/expanded ซ้าย) และ digit counter (ขวา)
- แนะนำให้ clear error state เมื่อ user เริ่มพิมพ์ใหม่ (ใน `onChanged` callback)
- Error message ควรชัดเจนและเป็นภาษาที่ user เข้าใจ
- ตัวอย่าง error messages:
  - "กรุณากรอกเบอร์มือถือให้ครบ 10 หลัก"
  - "เบอร์มือถือไม่ถูกต้อง"
  - "เบอร์มือถือนี้ถูกใช้งานแล้ว"

## Integration Checklist
- [ ] ติดตั้ง dependencies: `flutter_svg`, `google_fonts`
- [ ] เพิ่ม flag_th.svg, arrow-down-01.svg และ cancel-circle.svg ใน assets
- [ ] สร้าง ThemeColors helper class พร้อม color tokens
- [ ] กำหนด theme colors สำหรับ dark และ light mode (รวม text/base/400 opacity 45%)
- [ ] Import MobileCodeInput widget
- [ ] ทดสอบการทำงานใน dark/light mode
- [ ] ทดสอบ country code selector และ clear button
- [ ] ทดสอบ digit counter และ max length validation
- [ ] ทดสอบการกรอกเกิน maxLength (ต้องไม่สามารถกรอกได้)
- [ ] ทดสอบ error state (border สีแดง, error message ซ้าย, counter ขวา)
- [ ] ทดสอบการ clear error เมื่อ user พิมพ์ใหม่
- [ ] กำหนด text/base/danger color token สำหรับ error state
- [ ] เพิ่มธงชาติประเทศอื่นๆ ตามต้องการ
- [ ] กำหนด maxLength ที่เหมาะสมสำหรับแต่ละประเทศ
- [ ] เขียน validation logic สำหรับเบอร์มือถือแต่ละประเทศ

## Notes
- Widget รองรับ responsive width (ใช้ `double.infinity`)
- รับเฉพาะตัวเลข (digits only)
- จำกัดจำนวนตัวเลขด้วย `LengthLimitingTextInputFormatter`
- รองรับ Thai language ด้วย Noto Sans Thai font
- Memory management: dispose controllers และ listeners อัตโนมัติ
- Country code selector ต้องจัดการโดย parent widget
- Digit counter อัปเดตแบบ real-time ผ่าน `setState`
- Widget ใช้ `Column` layout เพื่อจัดวาง input และ counter/error message
- Error state ควบคุมโดย parent widget (controlled component pattern)
- แนะนำให้ clear error state ใน `onChanged` callback เพื่อ UX ที่ดี
- Error message และ digit counter แสดงพร้อมกันใน error state (error message ซ้าย, counter ขวา)
- ใช้ Row layout สำหรับแสดง error message และ counter ในบรรทัดเดียวกัน
