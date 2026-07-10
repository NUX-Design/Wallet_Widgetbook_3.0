# Theme V3

Theme V3 เป็นระบบสีแบบ additive ที่แยกออกจาก legacy theme โดยสมบูรณ์

เอกสารอธิบาย architecture, หน้าที่ของทุกไฟล์ และ maintenance workflow แบบละเอียดอยู่ที่ [`V3_THEME_GUIDELINE.mdx`](V3_THEME_GUIDELINE.mdx)

## Source of truth

ไฟล์ที่แก้ไขได้คือ:

- `tokens/primitive.tokens.json` — primitive color tokens จำนวน 145 รายการ
- `tokens/semantic/light.tokens.json` — semantic tokens สำหรับ Light mode จำนวน 55 รายการ
- `tokens/semantic/dark.tokens.json` — semantic tokensสำหรับ Dark mode จำนวน 55 รายการ

ไฟล์ใต้ `generated/` เป็น derived output ห้ามแก้ด้วยมือ ให้แก้ token inputs แล้ว generate ใหม่เท่านั้น

## Usage rule

Widget V3 ต้องเลือก semantic token ก่อน primitive เสมอ:

```dart
final colors = V3ThemeScope.colorsOf(context);
return ColoredBox(color: colors.backgroundPrimary);
```

ห้าม Theme V3 import `theme_color.dart`, เรียก `ThemeColors.get()` หรือ fallback ไป legacy theme ส่วน primitive constants ใช้สำหรับ generated semantic palette และกรณีที่ design specification ระบุไว้อย่างชัดเจนเท่านั้น

## Light/Dark workflow

1. แก้ primitive หรือ semantic JSON source
2. รักษา semantic paths ของ Light และ Dark ให้ตรงกัน
3. รัน generator จาก repo root:

   ```bash
   dart run lib/config/themes/v3/v3_theme_generator.dart
   ```

4. รัน targeted tests และ analyzer:

   ```bash
   flutter test test/config/themes/v3
   flutter analyze
   ```

`V3ThemeScope.colorsOf(context)` เลือก `V3ColorPalette.light` หรือ `.dark` จาก `Theme.of(context).brightness` โดยไม่แก้ `ThemeData` เดิม
