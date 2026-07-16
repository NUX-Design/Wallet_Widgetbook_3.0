# Claude Code Skill Pack — Skills V3

วางโฟลเดอร์ `.claude/` นี้ไว้ที่ root ของโปรเจกต์เป้าหมาย แล้วเปิด Claude Code จากโปรเจกต์นั้นเพื่อให้ skill ถูก discover ได้อัตโนมัติ

การเรียกใช้งาน:

- เรียกตรงด้วย `/flutter-widget-v3-beginner`
- หรือพิมพ์โจทย์ตามธรรมชาติ แล้วให้ Claude match จาก `description` ใน `SKILL.md`

Skills V3 ใช้ MCP server เดิม (`flutter-widget-wallet-mcp`) และเรียกเฉพาะ V3-prefixed tools (`*_v3_*`); ทำงานเฉพาะ `lib/widgets/v3/**` และห้าม migrate/overwrite widget เดิม ดู `docs/v3/V3_SKILLS_SPEC.md` สำหรับ canonical workflow และ tool routing เต็มรูปแบบ

แพ็กนี้ตั้งใจทำเป็น Claude Code native:

- แต่ละ skill ใช้ `SKILL.md` เป็น source-of-truth
- ไม่มี `agents/openai.yaml`
- ให้ใช้ร่วมกับ MCP config ของ `flutter-widget-wallet-mcp` ใน `.mcp.json` หรือ config ระดับ user (endpoint และ Bearer token เดิม)
- แพ็กนี้อยู่แยกจาก `skills/claude-code/.claude/skills/` (legacy) โดยสมบูรณ์; ไม่มีการแก้ legacy pack ใด ๆ

## Skills V3 ช่วยอะไร

Skills V3 เปลี่ยน catalog ของ Design System V3 ให้เป็น workflow ที่ Claude Code ทำตามได้อย่างเป็นขั้นตอน ตั้งแต่ตรวจ workspace, ค้นหา component, ดู preview, ดึง source ผ่าน MCP, ติดตั้ง, ปรับให้เข้ากับ Theme V3 ของโปรเจกต์ ไปจนถึง audit และ upgrade โดยไม่ fallback ไปใช้ legacy theme

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
/flutter-widget-v3-beginner สร้าง Flutter app ใหม่ชื่อ wi_wallet_demo
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

ส่ง context ที่ Inspector หรือ IDE ระบุให้ Claude Code เช่น:

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
- Claude Code ใช้ permission mode `default` เพราะ `auto` mode อาจบล็อก remote-bundle launcher แม้มี allow rule

### 1. ติดตั้ง pack ใน target project

รันจาก root ของ distribution repo นี้:

```bash
cp -R skills-v3/claude-code/.claude <TARGET_PROJECT_ROOT>/
chmod +x <TARGET_PROJECT_ROOT>/.claude/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs
```

### 2. ตั้ง Remote MCP และ token แบบ private

อ่าน token แบบไม่แสดงบนหน้าจอและไม่บันทึกใน shell history แล้วใช้ token เดียวกันกับ MCP และ preview bundle:

```bash
read -s MCP_BEARER_TOKEN
export MCP_BEARER_TOKEN
echo

claude mcp add --transport http flutter-widget-wallet-mcp \
  https://flutter-widget-wallet-mcp.onrender.com/mcp \
  --header "Authorization: Bearer ${MCP_BEARER_TOKEN}"
```

token นี้ใช้ตั้ง MCP ครั้งแรกเท่านั้น เมื่อ MCP เชื่อมต่อแล้ว preview launcher ใช้ signed URL อายุสั้นจาก MCP โดยอัตโนมัติ ผู้ใช้ไม่ต้องตั้ง `MCP_REMOTE_BEARER_TOKEN` เพิ่มและ Skill ต้องไม่ถามหา token ใน chat

ปิดแล้วเปิด Claude Code ใหม่จาก shell เดิมเพื่อให้ process เห็น environment variable:

```bash
cd <TARGET_PROJECT_ROOT>
claude
```

### 2.1 ตั้ง Permission ให้ Claude Code แบบทีละขั้น

คำว่า permission mode `default` หมายถึงโหมดปกติที่ Claude Code แสดงชื่อว่า **Manual** ในหน้าจอ ผู้ใช้ยังเป็นคนกดยืนยันก่อน Claude รันคำสั่งสำคัญ จึงปลอดภัยกว่าโหมดที่อนุญาตทุกอย่างอัตโนมัติ

วิธีที่ง่ายที่สุด ไม่ต้องแก้ไฟล์ settings:

1. เปิด Claude Code ใน target project ด้วยคำสั่ง `claude`
2. ดูชื่อโหมดที่แถบด้านล่างของช่องพิมพ์ ถ้าเห็น **Manual** แปลว่าถูกต้องแล้ว
3. ถ้าเป็น **Auto**, **Plan** หรือโหมดอื่น ให้กด `Shift+Tab` ซ้ำจนเปลี่ยนเป็น **Manual** บาง terminal ใช้ `Alt+M` แทนได้
4. เรียก `/flutter-widget-v3-preview V3MiniButton`
5. ครั้งแรก Claude จะแสดง permission prompt สำหรับไฟล์ `launch-v3-preview.mjs` ให้ตรวจว่าพาธลงท้ายตรงกับข้อความนี้:

   ```text
   .claude/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs
   ```

6. ถ้าพาธตรง ให้เลือกอนุญาตคำสั่งนี้ จะอนุญาตเฉพาะครั้งนี้หรือจำการอนุญาตสำหรับคำสั่งนี้ก็ได้ตามตัวเลือกที่ Claude Code แสดง
7. ถ้าคำสั่งเป็น `node *`, `curl *`, มีไฟล์อื่นที่ไม่รู้จัก หรือพาธไม่ลงท้ายตามข้อ 5 ให้กดปฏิเสธและตรวจการติดตั้งใหม่

ถ้าต้องการตั้ง **Manual** เป็นค่าเริ่มต้นถาวรสำหรับ project นี้:

1. พิมพ์ `/config` ใน Claude Code
2. เปิดส่วน permission mode
3. เลือก **Manual** ซึ่งเป็นชื่อบนหน้าจอของค่า `default`
4. ปิดแล้วเปิด Claude Code ใหม่ จากนั้นตรวจว่าแถบด้านล่างแสดง **Manual**

อีกทางหนึ่งสำหรับผู้ที่แก้ JSON ได้ ให้สร้าง `.claude/settings.local.json` ใน target project โดยแทน `/absolute/path/to/target-project` ด้วยพาธจริงจากคำสั่ง `pwd`:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "defaultMode": "default",
    "allow": [
      "Bash(/absolute/path/to/target-project/.claude/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs *)"
    ]
  }
}
```

ตัวอย่าง ถ้า `pwd` แสดง `/Users/somchai/my-app` ให้เปลี่ยน rule เป็น:

```text
Bash(/Users/somchai/my-app/.claude/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs *)
```

ใช้ `settings.local.json` เพราะเป็นการตั้งค่าเฉพาะเครื่อง ไม่ควร commit ไฟล์ที่มีพาธส่วนตัวของผู้ใช้ ห้ามสร้าง allow rule กว้างแบบ `Bash`, `node *` หรือ `curl *` และไม่ต้องวาง token ใน chat หาก launcher แจ้ง `UNAUTHORIZED`

### 3. เรียก preview

ใน Claude Code:

```text
/flutter-widget-v3-preview V3MiniButton
```

หรือใช้ภาษาธรรมชาติ:

```text
ขอดู local live preview ของ V3MiniButton
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
<TARGET_PROJECT_ROOT>/.claude/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs --stop-all
```

### Troubleshooting

- `UNAUTHORIZED`: ให้ Skill ดึง metadata ใหม่หนึ่งครั้งเพราะ signed URL อาจหมดอายุ ถ้ายังไม่ผ่านให้ผู้ดูแลตรวจ hosted delivery configuration; ผู้ใช้ไม่ต้องส่งหรือตั้ง launcher token เพิ่ม
- `STALE_BUNDLE`: source commit ล่าสุดยังไม่ตรงกับ bundle ที่ publish ต้องให้ source repo merge/publish bundle ใหม่
- `NOT_BUILT`: commit นั้นยังไม่มี published bundle
- safety classifier block: ตรวจว่าใช้ permission mode `default` และอนุมัติเฉพาะ launcher ด้านบน
- ไม่มี URL: ถือว่ายังไม่สำเร็จจนกว่าจะเห็น `ok: true`; ให้ Claude poll tool task ต่อจน launcher จบ
