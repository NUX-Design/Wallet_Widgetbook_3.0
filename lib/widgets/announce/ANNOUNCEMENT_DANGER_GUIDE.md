# AnnouncementDanger Widget

Static critical alert component for displaying urgent error or cautionary messages.

## 📋 Overview

`AnnouncementDanger` เป็น widget แสดงข้อความเตือนระดับวิกฤต (Critical/Error) แบบคงที่ ไม่หายไปเอง เหมาะสำหรับแสดงข้อมูลที่ต้องการความสนใจจากผู้ใช้เป็นอย่างสูง เช่น ข้อผิดพลาดในการยืนยันตัวตน, การระงับบัญชี หรือคำเตือนความเสี่ยงสูง

## 🎨 Design Specs (Based on Figma)

https://www.figma.com/design/D7WVaC8n3foVLo6S3HuPn8/NUX-Widget-Wallet-Library?node-id=8419-2508&t=iDuXSF4PGrBWF1fw-4

- **Background Token**: `danger/600`
- **Text Token**: `text/base/danger`
- **Icon**: `lib/assets/images/Alert Icon.svg` tinted with `danger/500` at 24×24px
- **Border Radius**: 12px
- **Padding**: 16/8/16/8 (left/top/right/bottom)
- **Font**: Noto Sans Thai
  - Title: 11px, weight 700, line-height 1.27
  - Description: 11px, weight 500, line-height 1.45
- **Gap**: 4px between icon-text and title-description

## 📦 Import

```dart
import 'package:mcp_test_app/widgets/announce/announcement_danger.dart';
```

## 🚀 Usage

### Basic Usage (With Title)

```dart
AnnouncementDanger(
  title: 'Critical Action Required',
  description: 'Your verification has failed multiple times. Please contact support immediately.',
)
```

### Usage Without Title

```dart
AnnouncementDanger(
  title: '', // Empty title
  description: 'Warning: This transaction exceeds your daily limit.',
)
```

## 🌟 Behaviour

- แสดงข้อความเตือนระดับวิกฤตแบบคงที่ (ไม่หายไปเอง)
- ใช้สีจาก Design Tokens (`danger/600`, `danger/500`, `text/base/danger`)
- รองรับข้อความหลายบรรทัด
- ไม่มีแอนิเมชัน (static display)
- **Title แสดงเฉพาะเมื่อไม่ว่าง** (if title.isNotEmpty)
- **Icon และ text จัดชิดด้านบน** (crossAxisAlignment: start)

## 🎯 Properties

| Property           | Type              | Required | Default | Description                                      |
|--------------------|-------------------|----------|---------|--------------------------------------------------|
| `title`            | `String`          | Yes      | -       | หัวข้อข้อความเตือน (ตัวหนา, แสดงเฉพาะเมื่อไม่ว่าง) |
| `description`      | `String`          | Yes      | -       | รายละเอียดข้อความเตือน                          |
| `descriptionSpans` | `List<TextSpan>?` | No       | null    | Custom text spans สำหรับ description (optional) |

## 🎨 Design Tokens Used

- **Background**: `danger/600`
- **Text**: `text/base/danger`
- **Icon Tint**: `danger/500`
- **Font**: `GoogleFonts.notoSansThaiTextTheme()` for Thai language support

## 🔄 Relationship with AnnouncementWarning

`AnnouncementDanger` สืบทอดคุณสมบัติ (extends) มาจาก `AnnouncementWarning` โดยมีการเปลี่ยนเฉพาะพาเลทสี (Color Palette) ให้เป็นสีแดงตามมาตรฐาน Error/Danger state ของระบบ

## 🧪 Preview

รันตัวอย่างพร้อมสลับธีม/ภาษาได้ที่:

```bash
flutter run lib/widgets/announce/preview_announcement_danger.dart
```

## ⚠️ Notes & Recommendations

1. **Urgency**: ใช้เฉพาะกรณีที่ต้องการความสนใจสูงสุดหรือมีข้อผิดพลาดรุนแรงเท่านั้น (หากเป็นคำเตือนทั่วไปให้ใช้ `AnnouncementWarning`)
2. **Fixed Colors**: Widget ใช้สีคงที่ตาม Figma spec เพื่อรักษาความหมายของระดับความรุนแรง (Danger = Red)
3. **Dismiss State**: ไม่มีปุ่มปิด เนื่องจากข้อมูลมักจะเป็นสิ่งที่ผู้ใช้ต้องจัดการหรือรับทราบก่อนดำเนินการต่อ

---

**Based on Figma Design**: Component ถูกสร้างตาม Figma spec node `state=danger` ใน NUX Widget Wallet Library
