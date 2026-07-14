# Theme V3

Theme V3 เป็นระบบ token แบบ additive ที่แยกออกจาก legacy theme โดยสมบูรณ์

เอกสารอธิบาย architecture, หน้าที่ของทุกไฟล์ และ maintenance workflow แบบละเอียดอยู่ที่ [`V3_THEME_GUIDELINE.mdx`](V3_THEME_GUIDELINE.mdx)

## Mandatory design reference

ก่อนสร้างหรือแก้ Theme V3/Widget V3 ต้องอ่าน [`../../../DESIGN.md`](../../../DESIGN.md) และยึดเป็น source of truth ด้าน design language, visual rules, token intent, typography, spacing, radius, shadows/effects และ component variants

- `DESIGN.md` ตอบว่า design ต้องมีหน้าตาและความหมายอย่างไร
- `tokens/**` ตอบว่าค่าใดถูกป้อนเข้า Theme V3 generator
- `generated/**` และ public Dart APIs เป็นผลลัพธ์สำหรับ runtime
- หาก reference กับ token/runtime ไม่ตรงกัน ให้หยุดและ reconcile ผ่าน token workflow ห้ามแก้ generated file, hardcode ค่า หรือ fallback ไป legacy theme

## Source of truth

ไฟล์ที่แก้ไขได้คือ:

- `tokens/primitive/primitive.tokens.json` — direct Figma primitive color export จำนวน 145 รายการ
- `tokens/primitive/color.alpha.json` — primitive alpha color จำนวน 52 รายการ
- `tokens/primitive/radius.json` — primitive radius จำนวน 9 รายการ
- `tokens/primitive/space.json` — primitive spacing จำนวน 18 รายการ
- `tokens/primitive/shadow.effect.json` — primitive shadow effects จำนวน 6 scales / 10 layers
- `tokens/semantic/light.tokens.json` — semantic tokens สำหรับ Light mode จำนวน 55 รายการ
- `tokens/semantic/dark.tokens.json` — semantic tokensสำหรับ Dark mode จำนวน 55 รายการ
- `tokens/semantic/radius.json` — semantic radius จำนวน 9 รายการ
- `tokens/semantic/space.json` — semantic spacing จำนวน 18 รายการ
- `tokens/semantic/typography.json` — semantic typography จำนวน 18 styles

ไฟล์ใต้ `generated/` เป็น derived output ห้ามแก้ด้วยมือ ให้แก้ token inputs แล้ว generate ใหม่เท่านั้น

## Usage rule

Widget V3 ต้องเลือก semantic token ก่อน primitive เสมอ:

```dart
final colors = V3ThemeScope.colorsOf(context);
return ColoredBox(color: colors.backgroundPrimary);
```

ห้าม Theme V3 import `theme_color.dart`, เรียก `ThemeColors.get()` หรือ fallback ไป legacy theme ส่วน primitive constants ใช้สำหรับ generated semantic palette และกรณีที่ design specification ระบุไว้อย่างชัดเจนเท่านั้น

Widget ควรเรียก radius และ spacing ผ่าน semantic APIs:

```dart
import 'package:mcp_test_app/config/themes/v3/v3_dimensions.dart';

const radius = V3Radii.roundedXl;
const gap = V3Spacing.space16;
```

`v3_primitives.dart` ยังคงใช้สำหรับ alpha colors และกรณีที่ design specification ระบุให้เข้าถึง primitive โดยตรงเท่านั้น

Typography และ primitive shadow effects:

```dart
import 'package:mcp_test_app/config/themes/v3/v3_primitives.dart';
import 'package:mcp_test_app/config/themes/v3/v3_typography.dart';

final titleStyle = V3Typography.headingMedium;
final cardShadow = V3PrimitiveShadows.md;
```

Typography ใช้ semantic role จาก Figma ส่วน shadow ยังเป็น primitive scale จนกว่าจะมี role mapping เช่น card, dropdown หรือ modal จาก Design

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
