# Theme System & Design Tokens Guide

เอกสารนี้อธิบายโครงสร้างระบบ Theme, Design Tokens และขั้นตอนการอัปเดตค่าสีในโปรเจกต์นี้อย่างละเอียด

> **ขอบเขตของเอกสาร:** เนื้อหาด้านล่างอธิบาย legacy theme เท่านั้น สำหรับงาน Theme V3 หรือ Widget V3 ต้องอ่านและยึด [`../../../DESIGN.md`](../../../DESIGN.md) เป็น design-system reference ก่อนเสมอ แล้วใช้ [`v3/V3_THEME_GUIDELINE.mdx`](v3/V3_THEME_GUIDELINE.mdx) เป็น source of truth ด้าน Flutter token architecture/generation ห้ามนำ `theme.json`, `ThemeColors.get()` หรือแนวทาง legacy ในเอกสารนี้ไปใช้กับ V3

สำหรับ V3 ให้ตีความ `DESIGN.md` เป็น source of truth ด้าน design intent, visual rules, semantic usage, typography, spacing, radius, effects และ component variants ส่วน `v3/tokens/**` คือ editable implementation source ที่ runtime generator อ่านจริง หากข้อมูลไม่ตรงกันต้อง reconcile ที่ source ห้าม hardcode หรือ fallback กลับ legacy theme

## 1. โครงสร้างไฟล์ (File Structure)

ระบบ Theme ประกอบด้วย 4 ไฟล์หลักที่ทำงานร่วมกัน:

| ไฟล์ | หน้าที่ (Responsibility) | ประเภท |
| :--- | :--- | :--- |
| **`theme.json`** | **Source of Truth** เก็บค่าสีทั้งหมด (Design Tokens) แยกตาม Light/Dark mode | 📝 Config (JSON) |
| **`theme_generator.dart`** | **Script** สำหรับอ่าน `theme.json` และสร้างไฟล์ `theme_color.dart` | ⚙️ Tool |
| **`theme_color.dart`** | **Generated Code** ที่รวบรวมค่าสีทั้งหมดให้เรียกใช้ได้ในแอป (ห้ามแก้ไขไฟล์นี้โดยตรง) | 💻 Generated |
| **`base_theme.dart`** | **Bridge** เชื่อมโยง Design Tokens เข้ากับ Flutter Material Theme (`ColorScheme`, `TextTheme`) | 🎨 Flutter Theme |

---

## 2. Design Tokens (`theme.json`)

นี่คือไฟล์ต้นฉบับที่คุณต้องแก้ไขเมื่อต้องการเปลี่ยนสี รูปแบบข้อมูลเป็น JSON Array:

```json
[
  {
    "name": "Color Theme",
    "values": [
      {
        "mode": { "name": "Light" },
        "color": [
          { "name": "primary/400", "value": "#f2c564" },
          { "name": "alt/base/300", "value": "#00000029" } // รองรับ 8-digit hex (RRGGBBAA)
        ]
      },
      {
        "mode": { "name": "Dark" },
        "color": [...]
      }
    ]
  }
]
```

*   **Format สี:** รองรับทั้ง 6 หลัก (`#RRGGBB`) และ 8 หลัก (`#RRGGBBAA` สำหรับสีโปร่งแสง)

---

## 3. ขั้นตอนการอัปเดต Design Tokens (Workflow)

เมื่อมีการเปลี่ยนแปลง Design Tokens (เช่น Designer ปรับเฉดสีใหม่) ให้ทำตามขั้นตอนดังนี้:

### Step 1: แก้ไขไฟล์ `theme.json`
เปิดไฟล์ `lib/config/themes/theme.json` และแก้ไขค่า `value` ของ Token ที่ต้องการ

### Step 2: รันคำสั่ง Generate
เปิด Terminal ใน Root Directory ของโปรเจกต์ และรันคำสั่ง:

```bash
dart run lib/config/themes/theme_generator.dart
```

รอจนขึ้นข้อความ:
`INFO: ... ThemeColors has been successfully generated from theme.json`

### Step 3: ตรวจสอบผลลัพธ์
*   ไฟล์ `lib/config/themes/theme_color.dart` จะถูกอัปเดตอัตโนมัติ
*   ทำการ **Hot Restart** แอปเพื่อดูสีใหม่

---

## 4. การเรียกใช้งานในโค้ด (Usage)

### 4.1 การใช้ผ่าน `ThemeColors` (Direct Access)
ใช้เมื่อต้องการเข้าถึง Token โดยตรง (เช่น กำหนดสี Border, Shadow หรือสีเฉพาะจุด)

```dart
import 'package:mcp_test_app/config/themes/theme_color.dart';

// วิธีใช้: ThemeColors.get(mode, token_name)
// mode: 'light' หรือ 'dark' (ปกติจะเช็คจาก Theme.of(context).brightness)

Container(
  color: ThemeColors.get(
    Theme.of(context).brightness == Brightness.light ? 'light' : 'dark',
    'fill/base/300'
  ),
);
```

### 4.2 การใช้ผ่าน `Theme.of(context)` (Standard Material)
ใช้เมื่อต้องการสีมาตรฐานของระบบ (ที่ถูก map ไว้ใน `base_theme.dart` แล้ว)

```dart
// ใช้สี Primary
Color primary = Theme.of(context).colorScheme.primary;

// ใช้สี Background
Color bg = Theme.of(context).colorScheme.surface;

// ใช้ Text Style
TextStyle headline = Theme.of(context).textTheme.headlineLarge!;
```

---

## 5. การทำงานของ Generator (`theme_generator.dart`)

Script นี้ทำหน้าที่:
1.  อ่านไฟล์ `theme.json`
2.  วนลูปอ่านค่าสีของแต่ละ Mode (Light/Dark)
3.  สร้าง Class `ThemeColors` ที่มี Static Map ของสีทั้งหมด
4.  สร้าง Helper Method:
    *   `_hex(String hex)`: แปลง String Hex เป็น Object `Color` ของ Flutter (รองรับการจัดการ Alpha Channel ให้ถูกต้อง)
    *   `get(String mode, String token)`: Method สำหรับดึงค่าสีตาม Mode อย่างปลอดภัย (มี Fallback ป้องกัน Crash)
5.  เขียนทับไฟล์ `theme_color.dart`

> **Note:** หากมีการแก้ไข Logic การแปลงสี หรือโครงสร้าง Class ให้แก้ที่ไฟล์นี้ แล้วรันคำสั่ง Generate ใหม่
