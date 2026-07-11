# Widget V3 Conventions

เอกสารนี้เป็นกติกาสำหรับ reusable widgets ที่สร้างบน Theme V3 โดยไม่เปลี่ยนหรือ migrate widget เดิม

## Structure And Naming

```text
lib/widgets/v3/<category>/
├── v3_<widget>.dart
├── preview_v3_<widget>.dart
└── V3_<WIDGET>_GUIDE.md

test/widgets/v3/<category>/
└── v3_<widget>_test.dart
```

- path และชื่อ public class ต้องสื่อ `v3` ชัดเจน; public widget class ขึ้นต้นด้วย `V3`
- หนึ่งไฟล์หลักควรมี reusable widget ที่รับข้อมูลและ callbacks ผ่าน constructor แบบ explicit
- ห้าม import widget หรือ theme V3 จาก widget เดิมที่อยู่นอก `lib/widgets/v3/`

## Theme And Color Rules

- อ่าน semantic palette ผ่าน `V3ThemeScope.colorsOf(context)` เท่านั้น
- ห้าม import legacy theme และห้ามเรียก `ThemeColors.get()`
- ใช้ semantic token สำหรับสีเชิงหน้าที่; ห้ามใช้ raw `Color(...)` เมื่อมี semantic token รองรับ
- ไม่ใช้ primitive token โดยตรง เว้นแต่ design specification ระบุเหตุผลและ local guide บันทึกข้อยกเว้น
- ทุก widget ต้องทำงานใน Light/Dark โดยไม่ต้องรับ mode string จาก caller

## API, Localization And Accessibility

- reusable widget ไม่ hardcode user-facing copy; ให้ caller ส่ง localized text เข้ามา
- รองรับ text scaling และหลีกเลี่ยง fixed width ที่ทำให้ข้อความล้น
- interactive widget ต้องมี target อย่างน้อย 48x48 logical pixels, keyboard focus, disabled state และ semantics ที่เหมาะสม
- icon-only action ต้องรับ semantic label ที่ localized แล้วจาก caller
- animation ต้องไม่เป็นเงื่อนไขเดียวที่สื่อ state และควรสั้นพอไม่ขัดขวางการใช้งาน

## Preview, Test And Guide Requirements

- มี standalone preview ที่เปิดดู Light/Dark ได้โดยไม่พึ่ง app flow
- preview ต้องแสดง state สำคัญ เช่น default, interactive, disabled, loading หรือ error ตามประเภท widget
- targeted tests ต้องครอบคลุม token mapping ใน Light/Dark, callback/disabled behavior, semantics และ text scaling ที่เกี่ยวข้อง
- local guide ต้องมี usage example, public API, state behavior, accessibility notes และ metadata ตามรูปแบบด้านล่าง

## Required Metadata

Local guide ทุกไฟล์ต้องมี section `V3 Metadata` และประกาศอย่างน้อย:

```yaml
Theme system: V3
Widget: V3Example
Category: example
Source: lib/widgets/v3/example/v3_example.dart
Preview: lib/widgets/v3/example/preview_v3_example.dart
Test: test/widgets/v3/example/v3_example_test.dart
Semantic tokens:
  - content/primary
  - background/primary
```

ชื่อ token ใช้ slash-separated source path เพื่อให้เอกสารและ MCP metadata อ่านตรงกับ token catalog
