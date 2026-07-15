# Kiro Skill Pack — Skills V3

วางโฟลเดอร์ `.kiro/` นี้ไว้ที่ root ของโปรเจกต์เป้าหมายเพื่อให้ Kiro discover skills ชุดนี้จาก `.kiro/skills/`

Skills V3 ใช้ MCP server เดิม (`flutter-widget-wallet-mcp`) และเรียกเฉพาะ V3-prefixed tools (`*_v3_*`); ทำงานเฉพาะ `lib/widgets/v3/**` และห้าม migrate/overwrite widget เดิม ดู `docs/v3/V3_SKILLS_SPEC.md` สำหรับ canonical workflow และ tool routing เต็มรูปแบบ

แพ็กนี้ตั้งใจทำเป็น Kiro native:

- แต่ละ skill ใช้ `SKILL.md` เป็น source-of-truth
- ไม่มี `agents/openai.yaml`
- ใช้ร่วมกับ MCP config ของ `flutter-widget-wallet-mcp` ผ่านการตั้งค่า MCP ของ Kiro (endpoint และ Bearer token เดิม)
- แพ็กนี้อยู่แยกจาก `skills/kiro/.kiro/skills/` (legacy) โดยสมบูรณ์; ไม่มีการแก้ legacy pack ใด ๆ

## Remote-safe fallback

Remote MCP เปิดเฉพาะ read-only V3 tools หาก workflow ต้องสร้าง widget หรือ Widgetbook use case ให้ skill ดึง template, metadata, tokens และ preview ผ่าน Remote MCP แล้วเขียน source ในโปรเจกต์ปลายทางเอง ส่วน `generate_v3_widget_code` และ `generate_v3_widgetbook_use_case` เป็นตัวเลือกเฉพาะ local/stdio MCP และห้าม fallback ไป legacy tools

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
