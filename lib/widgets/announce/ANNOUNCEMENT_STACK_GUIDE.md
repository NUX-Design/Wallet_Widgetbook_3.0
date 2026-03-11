# AnnouncementStack Widget

Stacked announcement cards with dismiss animation for short system messages.

## 📋 Overview

`AnnouncementStack` แสดงข้อความประกาศเรียงซ้อน 3 ชั้น ด้านหน้ามีปุ่มปิดเพื่อไล่ข้อความถัดไปขึ้นมา เหมาะสำหรับ banner แจ้งเตือนในแดชบอร์ดหรือหน้าหลัก

https://www.figma.com/design/D7WVaC8n3foVLo6S3HuPn8/New-Wi-Wallet-2.0?node-id=7089-198751&t=15GhVT2vXbRlmdTk-4


## 🎨 Design Specs

- Layout สูงคงที่ `80` px (ปรับด้วย parent ได้)
- **Light Theme**: การ์ดหน้า `fill/base/300`, กลาง `fill/base/400`, หลัง `fill/base/500`
- **Dark Theme**: การ์ดหน้า `fill/base/300` (#1A1A1A), กลาง `fill/base/400`, หลัง `fill/base/500`
- รัศมีมุม 12 px
- Padding ภายในการ์ด: 16/8/16/8
- ไอคอน HugeIcons (megaphone-01 / cancel-01) ขนาด 16x16 px
- Font: Noto Sans, 11px, weight 500, line-height 1.45
- **Text Truncation**: ตัดข้อความที่ยาวเกิน 3 บรรทัดด้วย `...` (Ellipsis)

## 📦 Files Structure

### Base Widget
- **[announcement.dart](announcement.dart)** - Pure base widget, ไม่มี preview code หรือ hardcoded data

### Preview Widget
- **[preview_announcement.dart](preview_announcement.dart)** - Standalone preview app พร้อม theme/locale switching และ mock data

## 📦 Import

```dart
import 'package:mcp_test_app/widgets/announce/announcement.dart';
```

## 🚀 Usage

```dart
AnnouncementStack(
  messages: const [
    'System maintenance finishes at 16:30 (Thailand time).',
    'Security upgrade in progress, back by 17:00.',
    'Your account is now fully verified as of 08:00 tomorrow.',
  ],
  onClose: () {
    // Optional: track dismiss or replace messages
  },
  isLoading: false, // Set to true to show skeleton loading state
)
```

## 🔌 Integration

ปัจจุบัน Widget นี้ถูกนำไปใช้งานใน `lib/main.dart` โดยวางอยู่ในส่วน Shortcut Menu (ด้านบนของปุ่มเมนู) เพื่อแจ้งข่าวสารสำคัญให้กับผู้ใช้งาน

```dart
// lib/main.dart
Container(
  // ... decoration ...
  child: Column(
    children: [
      const SizedBox(height: 24),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: AnnouncementStack(
          messages: [...], // Load from API or localization
        ),
      ),
      // ... shortcut buttons ...
    ],
  ),
)
```

## 🌟 Behaviour

- ปุ่มปิดจะเลื่อนการ์ดหน้าออก (slide left) แล้วนำไปต่อท้ายรายการ
- การ์ดกลางเลื่อนขึ้นมาด้านหน้า (slide up + scale) เพื่อรักษา stack 3 ชั้น
- ไม่อนุญาตให้กดปิดหากเหลือข้อความ ≤ 1 รายการ
- Widget จะ handle empty messages โดยแสดง placeholder cards
- Callback `onClose` ถูกเรียกหลังอนิเมชันจบ สามารถใช้โหลดข้อมูลใหม่หรือบันทึกสถิติได้
- ข้อความที่ยาวเกินพื้นที่จะถูกตัด (truncate) ที่บรรทัดที่ 3 พร้อมแสดง `...` เพื่อรักษา layout ของการ์ด

## 🎯 Properties

| Property    | Type            | Required | Default | Description                                    |
|-------------|-----------------|----------|---------|------------------------------------------------|
| `messages`  | `List<String>`  | No       | `[]`    | รายการข้อความที่จะวนแสดง (รองรับ empty list)   |
| `onClose`   | `VoidCallback?` | No       | null    | เรียกเมื่อผู้ใช้กดปิดการ์ดหน้า                |
| `debugMode` | `bool`          | No       | false   | สถานะดีบัก (สำหรับการพัฒนาในอนาคต)           |
| `isLoading` | `bool`          | No       | false   | แสดง skeleton loading state                    |

## 🎨 Design Tokens Used

- **Light Theme**: `text/base/600` (black), `fill/base/300-500` (light gray to darker)
- **Dark Theme**: `text/base/600` (white), `fill/base/300-500` (#1A1A1A to darker)
- ตัวอักษรใช้ `GoogleFonts.notoSans` ปรับขนาด 11 / น้ำหนัก 500 / line-height 1.45
- ระยะห่าง: การ์ดเว้น `SizedBox(width: 4)` ระหว่างไอคอน-ข้อความ และข้อความ-ปุ่มปิด
- ไอคอนและข้อความชิดด้านบน (ไม่มี top padding)

## 🔁 Animations

- การ์ดหน้า: slide `Offset(0,0) → (-1.0,0)` + fade `1 → 0.25`, duration 280 ms (`easeInOutCubic`)
- การ์ดกลาง: slide `Offset(0,0.12) → (0,0)` + scale `0.95 → 1` + fade `0.85 → 1`, duration 320 ms (`easeOutCubic`)
- การ์ดหลังสุด: scale `0.90 → 0.94` + fade `0.60 → 0.75`, sync กับคอนโทรลเลอร์เดียวกับการ์ดกลาง
- ใช้ `TickerProviderStateMixin` ภายใน state เพื่อควบคุมสองคอนโทรลเลอร์

## 🧪 Preview

รันตัวอย่างพร้อมสลับธีม/ภาษาได้ที่:

```bash
flutter run lib/widgets/announce/preview_announcement.dart
```

ไฟล์ preview มี:
- ตัวเลือกธีม (light/dark)
- Selector สำหรับ locale ที่อาศัย `AppLocalizations`
- Callback `onClose` ที่หมุนข้อความตัวอย่างกลับไปท้ายลิสต์
- Mock data รวมถึง localized strings สำหรับทดสอบ

## 🔄 Public Methods

### `updateMessages(List<String> newMessages)`

อัปเดต messages จากภายนอก widget:

```dart
final announcementKey = GlobalKey<_AnnouncementStackState>();

AnnouncementStack(
  key: announcementKey,
  messages: initialMessages,
)

// Later, update messages dynamically
announcementKey.currentState?.updateMessages(newMessages);
```

## ⚠️ Notes & Recommendations

1. **Localization**: เพื่อรองรับข้อความ localized ควร map จาก ARB เป็น `messages` ก่อนส่งเข้า widget
2. **Empty State**: Widget รองรับ empty messages โดยจะแสดง placeholder cards
3. **Custom Icons**: สามารถเปลี่ยนไอคอน HugeIcons เป็นไอคอนอื่นได้โดยแก้ `createHugeIcon` ใน `_buildCard`
4. **Layout Flexibility**: ความสูง widget ผูกกับจำนวนข้อความและ padding; ถ้าต้องการ layout ยืดหยุ่น สามารถห่อ `AnnouncementStack` ด้วย `Flexible` / `SizedBox.expand`
5. **Skeleton Loading**: ใช้ `isLoading: true` เพื่อแสดง skeleton state ขณะโหลดข้อมูล

## 🏗️ Architecture

### Base Widget (`announcement.dart`)
- **Pure widget logic** - ไม่มี preview code
- **No hardcoded data** - รับ messages จาก parent เท่านั้น
- **Production-ready** - พร้อมใช้งานจริง
- **Stateful** - จัดการ animations และ state ภายใน

### Preview Widget (`preview_announcement.dart`)
- **Standalone app** - มี `main()` function
- **Theme switching** - รองรับ light/dark mode
- **Locale switching** - ทดสอบ localization
- **Mock data** - ข้อความตัวอย่างสำหรับทดสอบ

---

## 🆕 Related Components

### AnnouncementWarning

Static warning alert component สำหรับแสดงข้อความเตือนที่สำคัญ:

```dart
import 'package:mcp_test_app/widgets/announce/announcement_warning.dart';

AnnouncementWarning(
  title: 'Please recheck information before proceeding',
  description: 'To prevent wrong account transfers or fraudulent activities.',
)
```

**Key Differences:**
- ไม่มีแอนิเมชัน (static display)
- ใช้สี warning คงที่ตาม Material Design
- เหมาะสำหรับข้อความเตือนที่สำคัญ
- ดู [ANNOUNCEMENT_WARNING_GUIDE.md](ANNOUNCEMENT_WARNING_GUIDE.md) สำหรับรายละเอียด

---

**Last Updated**: 2025-12-02 - Refactored to separate base widget from preview, removed hardcoded data, added skeleton loading support
