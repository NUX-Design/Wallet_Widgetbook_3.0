# Kiro Skill Pack — Skills V3

วางโฟลเดอร์ `.kiro/` นี้ไว้ที่ root ของโปรเจกต์เป้าหมายเพื่อให้ Kiro discover skills ชุดนี้จาก `.kiro/skills/`

Skills V3 ใช้ MCP server เดิม (`flutter-widget-wallet-mcp`) และเรียกเฉพาะ V3-prefixed tools (`*_v3_*`); ทำงานเฉพาะ `lib/widgets/v3/**` และห้าม migrate/overwrite widget เดิม ดู `docs/v3/V3_SKILLS_SPEC.md` สำหรับ canonical workflow และ tool routing เต็มรูปแบบ

แพ็กนี้ตั้งใจทำเป็น Kiro native:

- แต่ละ skill ใช้ `SKILL.md` เป็น source-of-truth
- ไม่มี `agents/openai.yaml`
- ใช้ร่วมกับ MCP config ของ `flutter-widget-wallet-mcp` ผ่านการตั้งค่า MCP ของ Kiro (endpoint และ Bearer token เดิม)
- แพ็กนี้อยู่แยกจาก `skills/kiro/.kiro/skills/` (legacy) โดยสมบูรณ์; ไม่มีการแก้ legacy pack ใด ๆ

## Skills V3 ช่วยอะไร

Skills V3 เปลี่ยน catalog ของ Design System V3 ให้เป็น workflow ที่ Kiro ทำตามได้อย่างเป็นขั้นตอน ตั้งแต่ตรวจ workspace, ค้นหา component, ดู preview, ดึง source ผ่าน MCP, ติดตั้ง, ปรับให้เข้ากับ Theme V3 ของโปรเจกต์ ไปจนถึง audit และ upgrade โดยไม่ fallback ไปใช้ legacy theme

Use cases หลัก:

- **เริ่ม Flutter project ใหม่** — สร้างแอปด้วย `flutter create`, ติดตั้ง Theme V3 runtime, เพิ่ม starter Widget V3, Light/Dark entrypoint, preview และ tests หลังผู้ใช้ยืนยันแผนแล้ว
- **เพิ่ม Widget V3 ใน Flutter project เดิม** — รักษา architecture และ business logic เดิม ติดตั้ง component ใต้ `lib/widgets/v3/**` แล้วปรับ semantic tokens ให้ใช้ `V3ThemeScope` ของโปรเจกต์ปลายทาง
- **ทำงานจาก element ที่เลือก** — ใช้ widget class, source file, line number หรือ widget-tree context ที่ได้จาก Flutter Inspector, DevTools หรือ IDE เป็น integration target เพื่อค้นหา preview และติดตั้ง component ที่เหมาะสม
- **แปลง Figma เป็น Flutter UI** — ตรวจหา component ที่ reuse ได้ก่อน แล้วจึงสร้าง Widget V3 ใหม่จาก template และ semantic tokens เมื่อ catalog ไม่มีตัวที่ตรง
- **ดูแล component ระยะยาว** — audit raw colors/legacy leakage และ selective upgrade โดยรักษา local customization

> Flutter Inspector เป็นผู้ให้ context ของ element ที่เลือก Skills V3 ไม่ได้ควบคุม Inspector โดยตรง การแก้ application screen นอก V3 paths ต้องรวมอยู่ใน scope ที่ผู้ใช้ยืนยันอย่างชัดเจน

## Skills ทั้ง 8 ตัว

| Skill | ใช้เมื่อ | ทำอะไรได้ |
|---|---|---|
| `flutter-widget-v3-beginner` | เริ่มโปรเจกต์ใหม่ หรือโปรเจกต์เดิมยังไม่มี Theme V3 | Scan workspace, เสนอ scope, bootstrap โปรเจกต์/Theme V3, เพิ่ม starter widget, preview และ tests ตาม flow `ask → scan → summarize → confirm → execute` |
| `flutter-widget-v3-search` | รู้ use case แต่ไม่รู้ชื่อ component | ค้นหาจาก category, keyword, behavior หรือ design intent และเปรียบเทียบ semantic-token dependencies, preview และ adaptation effort |
| `flutter-widget-v3-install` | เลือก Widget V3 ได้แล้ว | ดึง metadata, Dart source และ preview ผ่าน MCP ติดตั้งลง V3 paths พร้อม guide/tests และเชื่อมกับ `V3ThemeScope` ของ target repo |
| `flutter-widget-v3-adapt` | Component ที่ import มาไม่เข้ากับ host app | ปรับ imports, API shape, naming, semantic tokens และ code patterns โดยรักษาพฤติกรรมเดิม |
| `flutter-widget-v3-preview` | ต้องการดู component ก่อนหรือหลังติดตั้ง | เปิด live browser preview ที่ตรวจ readiness แล้ว รองรับ Light/Dark และ consumer repo ที่ไม่มี Flutter/Dart |
| `flutter-widget-v3-figma-to-code` | มี Figma component หรือ design handoff | ตรวจ component ที่ reuse ได้, map ค่าไป semantic tokens และ scaffold Widget V3 ใหม่เฉพาะเมื่อจำเป็น |
| `flutter-widget-v3-audit` | ต้องการตรวจคุณภาพ integration | ตรวจ legacy imports, raw `Color(...)`, `V3ThemeScope`, preview, metadata และ tests พร้อมจัดลำดับ findings |
| `flutter-widget-v3-upgrade` | Local Widget V3 อาจเก่ากว่า MCP source | Diff local กับ source ล่าสุด แยก local customization/breaking changes และ selective sync เฉพาะส่วนที่เหมาะสม |

## Workflow แนะนำ

### สร้าง Flutter project ใหม่

```text
ใช้ flutter-widget-v3-beginner สร้าง Flutter app ใหม่ชื่อ wi_wallet_demo
สำหรับ Android, iOS และ Web ติดตั้ง Theme V3 และ starter V3 button
แสดงแผนและรอให้ฉันยืนยันก่อนแก้ไฟล์
```

### Import component เข้า Flutter UI เดิม

```text
search → preview → install → adapt → integrate → audit
```

```text
ค้นหา Widget V3 สำหรับ primary action ใน checkout footer
เปิด preview ของตัวเลือกที่เหมาะสมก่อน หลังฉันยืนยันให้ติดตั้งและ adapt
จากนั้นแทนที่เฉพาะ action นั้น โดยรักษา callbacks และ business logic เดิม
```

### ใช้ element ที่เลือกจาก Flutter Inspector

ส่ง context ที่ Inspector หรือ IDE ระบุให้ Kiro เช่น:

```text
Selected element: CheckoutFooter > ElevatedButton
Source: lib/features/checkout/presentation/checkout_page.dart
Intent: replace with the closest Primary Widget V3 button
Constraint: preserve onPressed, loading state, analytics, and layout
Flow: search → preview → confirm → install → adapt → integrate → audit
```

## Remote-safe fallback

Remote MCP เปิดเฉพาะ read-only V3 tools หาก workflow ต้องสร้าง widget หรือ standalone preview ให้ skill ดึง template, metadata, tokens และ preview ผ่าน Remote MCP แล้วเขียน source ในโปรเจกต์ปลายทางเอง `generate_v3_widget_code` เป็น optimization เฉพาะ local/stdio MCP; remote workflow ต้องประกอบ source จาก read-only V3 tools และห้าม fallback ไป legacy tools หรือสร้าง Widgetbook files

รายการ skills:

- `flutter-widget-v3-beginner`
- `flutter-widget-v3-search`
- `flutter-widget-v3-install`
- `flutter-widget-v3-adapt`
- `flutter-widget-v3-preview`
- `flutter-widget-v3-figma-to-code`
- `flutter-widget-v3-audit`
- `flutter-widget-v3-upgrade`

## Setup local live preview

`flutter-widget-v3-preview` เปิด preview บน `127.0.0.1` ได้จากทุก repo รวมถึง repo ที่ไม่มี Flutter โดยดาวน์โหลด Flutter Web bundle ที่ publish แล้วผ่าน MCP จากนั้นตรวจ SHA-256, cache นอก workspace และคืน URL หลัง HTTP readiness ผ่านเท่านั้น

### สิ่งที่ต้องมี

- Node.js ที่เรียกด้วย `node` ได้
- Remote MCP ชื่อ `flutter-widget-wallet-mcp` เชื่อมต่อสำเร็จ
- Bearer token ที่ได้รับจาก repository owner; ห้ามใส่ token ใน commit, README, screenshot หรือบทสนทนากับ agent

### 1. ติดตั้ง pack ใน target project

รันจาก root ของ distribution repo นี้:

```bash
cp -R skills-v3/kiro/.kiro <TARGET_PROJECT_ROOT>/
chmod +x <TARGET_PROJECT_ROOT>/.kiro/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs
```

### 2. ตั้ง Remote MCP และ token แบบ private

สร้างหรือแก้ `.kiro/settings/mcp.json` ใน target project (หรือเปิดผ่าน Command Palette → `Kiro: Open workspace MCP config (JSON)`) โดยอ้าง token จาก environment แทนการ hardcode:

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp": {
      "url": "https://flutter-widget-wallet-mcp.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer ${MCP_REMOTE_BEARER_TOKEN}"
      },
      "disabled": false
    }
  }
}
```

อย่า commit MCP config ที่มี token จากนั้นอ่าน token สำหรับ MCP แบบไม่แสดงบนหน้าจอ แล้วเปิด Kiro CLI จาก shell เดียวกันเพื่อให้ process เห็น environment variable:

```bash
read -s MCP_REMOTE_BEARER_TOKEN
export MCP_REMOTE_BEARER_TOKEN
echo

cd <TARGET_PROJECT_ROOT>
kiro-cli chat
```

ถ้าใช้ Kiro IDE ให้เปิด IDE จาก environment ที่มี `MCP_REMOTE_BEARER_TOKEN` หรือกำหนด secret ผ่านกลไกที่องค์กรจัดไว้ แล้วบันทึก MCP config เพื่อให้ server reconnect

ตัวแปรนี้ใช้ให้ Kiro เชื่อม MCP เท่านั้น preview launcher ใช้ signed URL อายุสั้นจาก MCP โดยอัตโนมัติและไม่ต้องใช้ launcher token แยก

ถ้า Kiro แสดง permission prompt ให้อนุมัติเฉพาะ executable นี้:

```text
<TARGET_PROJECT_ROOT>/.kiro/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs
```

### 3. เรียก preview

ขอให้ Kiro ใช้ skill โดยระบุชื่อ widget:

```text
ใช้ flutter-widget-v3-preview เปิด local live preview ของ V3MiniButton
```

ผลสำเร็จต้องมาจาก launcher ที่รายงาน `ok: true` หลัง readiness เช่น:

```json
{"ok":true,"reused":false,"url":"http://127.0.0.1:<port>/#/button/V3MiniButton"}
```

เปิด URL ที่ launcher คืนมาใน browser อย่ายึด port เดิม เพราะ port อาจเปลี่ยนในแต่ละเครื่องหรือ session ส่วน `reused: true` หมายถึง bundle/server ของ commit เดิมถูกนำกลับมาใช้

### 4. Source repo mode

ถ้า workspace มีทั้ง `lib/preview_v3/` และ `scripts/serve-v3-preview.sh` skill จะใช้ source-development mode อัตโนมัติ ไม่เรียก bundle launcher และไม่ต้องใช้ bearer token:

```bash
dart run tool/generate_v3_preview_registry.dart
./scripts/serve-v3-preview.sh
```

จากนั้นใช้ URL ที่ script ยืนยัน readiness แล้ว ซึ่งโดยปกติเป็น:

```text
http://127.0.0.1:8090/#/<category>/<WidgetClass>
```

### 5. หยุด consumer preview servers

```bash
<TARGET_PROJECT_ROOT>/.kiro/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs --stop-all
```

### Troubleshooting

- `UNAUTHORIZED`: ให้ Skill ดึง metadata ใหม่หนึ่งครั้งเพราะ signed URL อาจหมดอายุ ถ้ายังไม่ผ่านให้ผู้ดูแลตรวจ hosted delivery configuration; ห้ามส่ง token ใน chat
- `STALE_BUNDLE`: source commit ล่าสุดยังไม่ตรงกับ bundle ที่ publish ต้องให้ source repo merge/publish bundle ใหม่
- `NOT_BUILT`: commit นั้นยังไม่มี published bundle
- permission block: อนุมัติเฉพาะ launcher ด้านบนตาม permission settings ของ Kiro
- ไม่มี URL: ถือว่ายังไม่สำเร็จจนกว่าจะเห็น `ok: true`; ให้ Kiro poll tool task ต่อจน launcher จบ
