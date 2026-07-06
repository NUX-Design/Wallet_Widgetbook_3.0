# flutter-widget-beginner Skill Spec

สเปกนี้ออกแบบสำหรับ skill ชื่อ `flutter-widget-beginner`

เป้าหมายของ skill:
- scan workspace ก่อนว่ามี Flutter project อยู่แล้วหรือไม่
- ถ้ายังไม่มี ให้ bootstrap foundation สำหรับเริ่มใช้ widget จาก `flutter-widget-wallet-mcp`
- ถ้ามีอยู่แล้ว ให้เติมเฉพาะส่วนที่ขาดแบบมี scope ชัดเจน
- บังคับให้มี question flow เพื่อให้ user กำหนด intent และลดความเสี่ยงจากการแก้ repo กว้างเกินไป

## 1. หลักการของ skill

skill นี้ต้องทำงานแบบ:

1. `ask`
2. `scan`
3. `summarize`
4. `confirm`
5. `execute`

ห้าม execute ทันทีโดยไม่ถามก่อน เพราะ skill นี้อาจแตะ:
- โครงสร้าง Flutter project
- theme foundation
- localization foundation
- preview / Widgetbook
- tests
- starter widgets

## 2. สิ่งที่ skill ต้องตรวจจาก workspace

ก่อนตัดสินใจลงมือ skill ต้องสแกนอย่างน้อย:

- มี `pubspec.yaml` หรือไม่
- มี `lib/main.dart` หรือไม่
- มี Flutter package จริงหรือไม่
- มี `lib/widgets/` หรือ equivalent หรือไม่
- มี `lib/config/themes/` หรือ theme layer ที่ใช้งานจริงหรือไม่
- มี `lib/l10n/` และ `l10n.yaml` หรือไม่
- มี `test/` และ test harness หรือไม่
- มี preview entrypoints หรือ Widgetbook หรือไม่
- มี `assets/` หรือ placeholder asset structure หรือไม่

## 3. Question Flow ที่ต้องมี

คำถามควรมี 2 ช่วง:

### ช่วง A: Discovery Questions

ถามก่อน scan เพื่อรู้ intent ของผู้ใช้

### ช่วง B: Confirmation Questions

ถามหลัง scan เสร็จ โดยอ้างอิงจากสิ่งที่พบจริงใน workspace

## 4. Discovery Questions

### Q1. Goal

คำถาม:
- `รอบนี้ต้องการให้ flutter-widget-beginner ทำอะไร`

ตัวเลือก:

#### `scan-only`

ความหมาย:
- ให้ skill วิเคราะห์ repo อย่างเดียว
- ไม่สร้างไฟล์
- ไม่แก้โค้ด
- สรุปเฉพาะสิ่งที่พบ, สิ่งที่ขาด, และสิ่งที่แนะนำให้ทำต่อ

เหมาะเมื่อ:
- user ยังไม่แน่ใจสภาพ repo
- อยากดู gap analysis ก่อน
- ยังไม่อยากให้ระบบแก้อะไร

#### `bootstrap-existing`

ความหมาย:
- repo นี้มี Flutter project อยู่แล้ว หรือคาดว่าน่าจะมี
- ให้ skill เติม foundation เฉพาะส่วนที่ขาด
- หลีกเลี่ยงการรื้อของเดิม

เหมาะเมื่อ:
- มี `pubspec.yaml` และ `lib/main.dart` อยู่แล้ว
- อยากให้พร้อมใช้ widget จาก MCP ได้เร็วขึ้น
- อยากเพิ่ม preview/theme/l10n/tests โดยไม่สร้างโปรเจกต์ใหม่

#### `bootstrap-new`

ความหมาย:
- ถ้า repo ยังไม่มี Flutter project ให้สร้าง foundation ใหม่ให้พร้อมเริ่มต้น
- ถ้า repo มี Flutter อยู่แล้ว ให้ skill ต้องหยุดและขอ confirm ก่อน เพราะ intent นี้หมายถึงงานสร้างใหม่

เหมาะเมื่อ:
- repo ว่าง
- เป็น monorepo ที่ยังไม่มี Flutter package ส่วนนี้
- ต้องการ Flutter widget starter setup ตั้งแต่ต้น

### Q2. Workspace State Preference

คำถาม:
- `สภาพ workspace ตอนนี้เป็นแบบไหน หรืออยากให้ skill ตีความแบบไหน`

ตัวเลือก:

#### `existing-flutter`

ความหมาย:
- user เชื่อว่ามี Flutter project อยู่แล้ว
- skill ควร prioritize การ integrate เข้ากับโครงสร้างเดิม
- ถ้าสแกนแล้วไม่พบ Flutter project ต้องแจ้ง mismatch ให้ user ทันที

#### `no-flutter-yet`

ความหมาย:
- user ยืนยันว่า workspace นี้ยังไม่มี Flutter project
- skill สามารถวาง bootstrap plan แบบตั้งต้นใหม่ได้
- ถ้าสแกนแล้วกลับพบ Flutter project ต้องแจ้งและขอ confirm ก่อนทำต่อ

#### `auto-detect`

ความหมาย:
- ให้ skill scan แล้วตัดสินใจจากข้อเท็จจริง
- เป็น default ที่เหมาะสุด

### Q3. Foundation Level

คำถาม:
- `ต้องการ foundation ระดับไหน`

ตัวเลือก:

#### `minimal`

ความหมาย:
- เอาแค่ของจำเป็นให้เริ่มรัน preview/widget sample ได้

สิ่งที่ควรได้:
- Flutter entrypoint พื้นฐาน
- โฟลเดอร์ widget พื้นฐาน
- sample widget 1 ตัว
- preview entrypoint 1 ตัว

สิ่งที่ยังไม่จำเป็น:
- Widgetbook เต็ม
- localization เต็มระบบ
- test harness เต็ม

เหมาะเมื่อ:
- อยากเริ่มเร็ว
- ต้องการ proof-of-setup

#### `standard`

ความหมาย:
- เป็นค่าที่แนะนำที่สุด
- ต้องการ foundation ที่พร้อมใช้งานจริงระดับทีมเล็ก

สิ่งที่ควรได้:
- theme foundation
- preview system
- localization base
- test harness พื้นฐาน
- starter widget ที่ติดตั้งจาก MCP

เหมาะเมื่อ:
- จะเริ่มใช้งาน widget library จริง
- อยากให้ repo อยู่ในสภาพที่ต่อยอดได้ทันที

#### `full`

ความหมาย:
- ต้องการ foundation ครบที่สุดในรอบเดียว

สิ่งที่ควรได้:
- ทุกอย่างใน `standard`
- Widgetbook integration ถ้าเหมาะกับ repo
- docs/guide ขั้นต้น
- stricter folder structure
- starter samples มากกว่า 1 จุดถ้าจำเป็น

เหมาะเมื่อ:
- ตั้งใจยก repo นี้เป็น design-system/widget workspace จริงจัง
- ยอมรับการเปลี่ยนแปลงหลายไฟล์ได้

### Q4. Starter Widget

คำถาม:
- `ต้องการให้เริ่มต้นด้วย widget อะไร`

ตัวเลือก:

#### `Buttons`

ความหมาย:
- เริ่มด้วยปุ่มพื้นฐาน
- ดีสำหรับพิสูจน์ theme, states, preview และ reuse patterns

#### `SearchInput`

ความหมาย:
- เริ่มด้วย input widget
- ดีสำหรับพิสูจน์ form patterns และ state/input behavior

#### `Avatar`

ความหมาย:
- เริ่มด้วย display widget
- ดีสำหรับพิสูจน์ asset, layout, theme behavior

#### `auto`

ความหมาย:
- ให้ skill ใช้ MCP scan แล้วเลือก starter widget ที่เหมาะกับ repo context ที่สุด
- ควรเลือกจาก widget ที่ dependency ต่ำและ preview พร้อม

### Q5. Change Policy

คำถาม:
- `ให้ skill แตะ repo ได้ระดับไหน`

ตัวเลือก:

#### `additive-only`

ความหมาย:
- เพิ่มไฟล์/โค้ดใหม่ได้
- หลีกเลี่ยงการแก้ไฟล์เดิมเท่าที่ทำได้
- ถ้าต้องแก้ไฟล์เดิมจำนวนมาก ให้หยุดแล้วขอ confirm

เหมาะเมื่อ:
- repo มีโครงสร้างเดิมที่ไม่อยากให้ถูกรบกวน

#### `allow-structure-setup`

ความหมาย:
- อนุญาตให้ตั้งโครงสร้าง foundation ที่จำเป็น
- แก้ไฟล์เดิมได้ถ้าจำเป็นต่อการ bootstrap
- ยังไม่ควร overwrite ของผู้ใช้แบบเงียบ ๆ

เหมาะเมื่อ:
- ต้องการให้ skill ช่วย setup จริง ไม่ใช่แค่เพิ่มไฟล์ลอย ๆ

#### `ask-before-overwrite`

ความหมาย:
- skill สามารถเตรียมแผนแก้ไฟล์เดิมได้
- แต่ถ้าจะเปลี่ยนไฟล์สำคัญหรือมีความเสี่ยงชนของเดิม ต้องถามอีกครั้งก่อน execute

เหมาะเมื่อ:
- user อยากให้ skill proactive แต่ยังต้องมีจุด confirm

## 5. Confirmation Question หลัง scan

หลัง scan skill ต้องสรุปก่อนว่า:

- พบ Flutter project หรือไม่
- พบ foundation อะไรอยู่แล้วบ้าง
- คาดว่าจะเพิ่ม/แก้อะไรบ้าง
- มี risk ตรงไหน เช่น repo ไม่ใช่ Flutter, มีโครงสร้างชนกัน, มี theme/l10n เดิมอยู่แล้ว

จากนั้นถาม confirm ปิดท้าย:

### Q6. Execute Plan

คำถาม:
- `จากสิ่งที่สแกนพบ จะให้ดำเนินการตามแผนนี้หรือไม่`

ตัวเลือก:

#### `proceed`

ความหมาย:
- ลงมือทำตาม plan ที่สรุปไว้

#### `revise-scope`

ความหมาย:
- user อยากเปลี่ยนคำตอบบางข้อ เช่นลดจาก `full` เป็น `standard`
- skill ควรถามเฉพาะข้อที่เกี่ยวข้องใหม่

#### `stop-after-scan`

ความหมาย:
- จบที่ analysis report
- ไม่แก้ไฟล์

## 6. Decision Table

### ถ้าเลือก `scan-only`

ผลลัพธ์:
- scan workspace
- สรุป gap
- เสนอ next steps
- ไม่แก้ไฟล์

### ถ้าเลือก `bootstrap-existing`

ผลลัพธ์:
- scan Flutter repo เดิม
- identify missing foundation
- เติมส่วนที่ขาดตาม `foundation_level`
- ดึง starter widget จาก MCP
- เพิ่ม preview/test/l10n/theme เท่าที่จำเป็น

### ถ้าเลือก `bootstrap-new`

ผลลัพธ์:
- ถ้าไม่พบ Flutter project: สร้าง foundation ใหม่
- ถ้าพบ Flutter project: หยุดและให้ user confirm ก่อนว่าต้องการสร้างใหม่จริงหรือเปลี่ยนเป็น `bootstrap-existing`

### ถ้า `workspace_state_preference = auto-detect`

ผลลัพธ์:
- ให้ scan เป็นตัวชี้ขาด
- ใช้ผลจริงใน workspace มาก่อน assumption ของระบบ

### ถ้า `foundation_level = minimal`

ผลลัพธ์ที่ควรสร้าง:
- basic app structure
- starter widget 1 ตัว
- preview entrypoint 1 ตัว

### ถ้า `foundation_level = standard`

ผลลัพธ์ที่ควรสร้าง:
- minimal ทั้งหมด
- theme foundation
- localization base
- test harness base

### ถ้า `foundation_level = full`

ผลลัพธ์ที่ควรสร้าง:
- standard ทั้งหมด
- Widgetbook ถ้า repo เหมาะ
- repo docs/guide ขั้นต้น
- stronger folder conventions

## 7. สิ่งที่ skill ควรสร้างในแต่ละระดับ

### Minimal

- `lib/main.dart` หรือ integrate กับ entrypoint เดิม
- `lib/widgets/`
- starter widget
- preview file

### Standard

- ทุกอย่างใน Minimal
- `lib/config/themes/`
- `lib/l10n/`
- `test/support/widget_test_harness.dart`

### Full

- ทุกอย่างใน Standard
- Widgetbook setup ถ้า repo ต้องการ
- additional docs/guide
- stricter starter structure สำหรับ scale ต่อ

## 8. MCP Tools Mapping

skill นี้ควรใช้ MCP server ดังนี้:

- `get_design_system_info`
  ใช้ดึงกฎภาพรวมของ design-system

- `get_codebase_patterns`
  ใช้ดึง coding/structure patterns ที่เหมาะกับ repo ปลายทาง

- `list_categories`
  ใช้ดู inventory ระดับ category

- `search_widgets`
  ใช้เลือก starter widget

- `get_widget_metadata`
  ใช้ดู dependencies, previews, docs, assets

- `get_widget_code`
  ใช้ดึง source ของ widget ที่จะติดตั้ง

- `get_widget_preview`
  ใช้ดึง preview พร้อมใช้งาน

- `get_flutter_widget_template`
  ใช้ scaffold widget เปล่าถ้าจำเป็น

- `generate_widgetbook_use_case`
  ใช้เมื่อ scope ต้องการ Widgetbook

## 9. Guardrails

skill นี้ต้องไม่:

- overwrite ไฟล์สำคัญแบบเงียบ ๆ
- เดาว่า repo เป็น Flutter ถ้ายังไม่ได้ scan
- ฝืน bootstrap Flutter ลง repo ที่เป็น non-Flutter โดยไม่ confirm
- replace theme/l10n เดิมของ repo ทั้งชุดโดยอัตโนมัติ

skill นี้ต้อง:

- แจ้งสิ่งที่พบก่อน execute
- แยกชัดว่าอะไรคือ `new file`, `edit existing`, `optional integration`
- ใช้ `auto-detect` เป็น default ถ้า user ไม่ระบุสถานะ workspace

## 10. Recommended Defaults

ถ้า user ไม่ตอบเอง ให้ใช้ default เหล่านี้:

- `goal = bootstrap-existing`
- `workspace_state_preference = auto-detect`
- `foundation_level = standard`
- `starter_widget = auto`
- `change_policy = ask-before-overwrite`

เหตุผล:
- balance ดีที่สุดระหว่างความปลอดภัยกับความ useful

## 11. Example Interaction

### รอบถาม

1. รอบนี้ต้องการให้ skill ทำอะไร
2. สภาพ workspace ตอนนี้เป็นแบบไหน หรืออยากให้ skill ตีความแบบไหน
3. ต้องการ foundation ระดับไหน
4. ต้องการให้เริ่มต้นด้วย widget อะไร
5. ให้ skill แตะ repo ได้ระดับไหน

### รอบสรุปหลัง scan

ตัวอย่าง:

- พบ `pubspec.yaml` และ `lib/main.dart`
- พบว่า repo เป็น Flutter project อยู่แล้ว
- ยังไม่มี `lib/l10n/`
- ยังไม่มี test harness กลาง
- มี theme layer บางส่วนแล้ว
- มีความเหมาะสมที่จะเติมแบบ `bootstrap-existing + standard`

จากนั้นถาม:
- จะดำเนินการตามแผนนี้หรือไม่

## 12. สิ่งที่ควรทำต่อจากสเปกนี้

สเปกนี้พร้อมต่อยอดไปเป็น:

1. `SKILL.md` ฉบับจริง
2. question schema สำหรับ interactive runner
3. decision engine ของ skill
4. bootstrap implementation scripts
