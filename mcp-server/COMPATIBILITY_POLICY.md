# Compatibility Policy

อัปเดตล่าสุดเมื่อ: `2026-07-05 00:46:00 +0700`

เอกสารนี้เป็น source-of-truth สำหรับ `P7-04`

## Backward Compatibility Policy

สำหรับ MCP tool schema และ workflow ที่ published แล้ว ให้ถือกติกานี้:

- response fields เดิมที่ documented แล้วต้องไม่ลบหรือเปลี่ยน type ใน release แบบ `MINOR` หรือ `PATCH`
- field ใหม่ต้องเป็น optional หรือ additive เว้นแต่จะมี major release
- tool names เดิมต้องคงอยู่จนกว่าจะผ่าน deprecation process
- error codes เดิมที่ documented แล้วต้องคงความหมายเดิม
- installer flags และ client aliases ที่ documented แล้วต้องไม่เปลี่ยนเงียบๆ ใน non-major release

## Deprecation Process

1. ประกาศ deprecation ใน `CHANGELOG.md`
2. เพิ่ม note ใน docs ที่เกี่ยวข้องอย่างน้อยหนึ่งแห่ง เช่น `README.md` หรือ policy file นี้
3. คง behavior เดิมอย่างน้อยหนึ่ง `MINOR` release ถ้ายังทำได้อย่างปลอดภัย
4. ถ้าต้องลบจริง ให้ลบใน `MAJOR` release พร้อม migration note

## Breaking Change Communication

เมื่อมี breaking change:

1. bump `MAJOR` version
2. เพิ่ม changelog entry ใต้ `Changed` หรือ `Removed`
3. อัปเดต contract docs ใน `README.md`
4. อัปเดต troubleshooting/migration guidance ถ้าผู้ใช้ต้องแก้ config, scripts, หรือ tool calls
5. ระบุชัดว่า breaking change กระทบ:
   - tool names
   - required args
   - response schema
   - installer/config flow
   - observability env vars หรือ operational commands

## Contract Review Triggers

ถือว่าเป็น compatibility-sensitive และต้อง review ตาม policy นี้ถ้าแตะ:

- `tool_contracts.js`
- `app.js`
- `tool_runtime.js`
- `installer.js`
- `http-server.js`
- `remote_support.js`
- files ใน `mcp-server/tests/snapshots/`

## Client Support Matrix

### Officially supported: local `stdio`

- Claude Code: verify ผ่าน `npm run validate:onboarding`
- Codex: verify ผ่าน `npm run validate:onboarding`
- Cursor: verify ผ่าน `npm run validate:onboarding`

### Officially supported: remote `streamable-http`

- MCP SDK clients ที่ใช้ `StreamableHTTPClientTransport`: verify ผ่าน `npm run verify:mcp:http`
- Generic MCP clients ที่รับ remote URL และ custom headers ได้: supported ตาม protocol contract ใน `examples/remote.generic.mcp.json`

### Best-effort / unverified สำหรับ remote mode

- Claude Code remote URL flow
- Codex remote URL flow
- Cursor remote URL flow

หมายเหตุ:

- สำหรับ 3 client ข้างบน repo นี้ยังไม่มี automated host-app verification ของ remote URL integration โดยตรง
- จนกว่าจะมี client-specific remote smoke checks ให้ถือว่า local `stdio` คือ officially supported path สำหรับ desktop IDE/agent hosts เหล่านี้
- สำหรับ external desktop-host onboarding ที่ไม่อยาก clone repo แต่ก็ยังไม่อยากพึ่ง remote URL flow ตรง ๆ ให้ใช้ `mcp-remote` bridge เป็นเส้นทาง recommended แทน โดยอ้างอิง `examples/mcp-remote.generic.mcp.json` หรือ `examples/codex-chatgpt-agent.remote-bridge.mcp.json`
