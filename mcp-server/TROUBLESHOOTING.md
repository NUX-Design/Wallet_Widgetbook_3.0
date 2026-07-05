# Troubleshooting

อัปเดตล่าสุดเมื่อ: `2026-07-05 00:46:00 +0700`

เอกสารนี้เป็น source-of-truth สำหรับ `P7-02`

## Quick Debug Commands

```bash
cd mcp-server
npm run check:mcp-syntax
npm test
npm run verify:mcp
npm run evaluate:mcp
npm run validate:onboarding
```

ถ้าต้องการดู structured logs ของ runtime:

```bash
cd mcp-server
MCP_LOG_LEVEL=debug node index.js
```

## Known Failure Modes And Recovery Steps

### 1. `tools/list` หรือ `verify:mcp` fail ทันที

อาการ:
- Inspector verification fail ตั้งแต่เริ่ม
- error ว่า tool schema parse ไม่ได้ หรือ server start ไม่ขึ้น

เช็ก:
- `npm install` ถูกเรียกใน `mcp-server/`
- `node_modules/@modelcontextprotocol/inspector-cli/build/index.js` ยังมีอยู่
- `docs/schema.json` และ `lib/config/themes/theme.json` ยังอยู่ใน repo root

วิธีแก้:
1. รัน `npm run check:mcp-syntax`
2. รัน `npm test`
3. ถ้าเพิ่งแก้ contract ให้ตรวจ snapshots และ `tool_contracts.js`

### 2. Widget หาไม่เจอหรือ preview ไม่ถูกจับคู่

อาการ:
- `get_widget_metadata` หรือ `get_widget_preview` คืน `NOT_FOUND` / `EMPTY_RESULT`

เช็ก:
- widget อยู่ใต้ `lib/widgets/<category>/`
- preview ใช้ชื่อ `preview_*.dart` หรือ `*_preview.dart` หรืออย่างน้อย import widget เป้าหมายตรงๆ
- markdown docs อยู่ข้าง widget เป็น `*.md`

วิธีแก้:
1. รัน `search_widgets` หรือ `list_widgets` ก่อนเพื่อดู canonical name
2. ตรวจ preview/doc placement ตาม convention
3. ถ้าแก้ docs schema-facing ด้วย ให้รัน `npm run generate-schema` จาก repo root

### 3. Onboarding/config install พัง

อาการ:
- `install.js` merge config ไม่ได้
- client มองไม่เห็น server หลังติดตั้ง

เช็ก:
- settings path ชี้ไฟล์ JSON ที่ writable
- ถ้าไฟล์ malformed JSON คำสั่งควร fail พร้อม error ชัดเจน
- config examples และ `mcp.json.example` ยังชี้ `mcp-server/index.js`

วิธีแก้:
1. รัน `npm run validate:onboarding`
2. ลอง generate examples ใหม่ด้วย `npm run install-mcp`
3. reopen MCP client หลังอัปเดต config

### 4. Contract tests หรือ snapshots fail หลังแก้ schema

อาการ:
- `npm test` fail ที่ snapshot หรือ tool definition contracts

วิธีแก้:
1. ตรวจว่าการเปลี่ยน contract ตั้งใจจริง
2. ถ้าตั้งใจ ให้รัน `npm run test:update-snapshots`
3. review diff ใน `tests/snapshots/`
4. อัปเดต `README.md`, `CHANGELOG.md`, และ policy docs ถ้ากระทบ documented contract

### 5. ต้อง debug issue บนเครื่อง maintainer

วิธีเก็บหลักฐาน:
1. รันด้วย `MCP_LOG_LEVEL=debug`
2. เก็บ stderr output ที่เป็น JSON lines
3. ดู event หลัก:
   - `server.started`
   - `mcp.tools.list`
   - `tool.call.finish`
   - `tool.call.error`
   - `widget_catalog.load`
   - `widget_catalog.search`
4. ถ้าเป็น cache/freshness issue ให้ตรวจ `cache`, `generatedAt`, และ `cacheTtlMs`

## Escalation Guideline

- ถ้า bug กระทบ documented contract หรือ onboarding flow ให้ treat เป็น release-blocking
- ถ้า bug เป็น observability-only แต่ runtime ยังทำงานได้ ให้แก้ก่อน release ถ้ามีผลกับ debugability
