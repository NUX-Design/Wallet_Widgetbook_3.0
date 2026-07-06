# MCP Client Config Examples

ไฟล์ในโฟลเดอร์นี้แบ่งเป็น 2 กลุ่ม:

## 1. Local `stdio` examples

- `claude-code.mcp.json`
- `codex-chatgpt-agent.mcp.json`
- `cursor.mcp.json`

หมายเหตุ:

- ตัวอย่างที่ commit ไว้ใช้ placeholder path `"/ABSOLUTE/PATH/TO/PROJECT/mcp-server/index.js"`
- ถ้าต้องการไฟล์ที่มี absolute path ของเครื่องคุณจริง ให้รัน:

```bash
cd mcp-server
npm run install-mcp
```

- คำสั่งข้างบนจะ regenerate `mcp.json.example` และไฟล์ตัวอย่าง local stdio ในโฟลเดอร์นี้ให้ชี้ path จริงของ repo ปัจจุบัน
- ถ้าต้องการเขียนลงไฟล์ settings ของ client โดยตรง ให้ใช้:

```bash
node install.js --client claude-code --settings /absolute/path/to/mcp.json
node install.js --client codex-chatgpt-agent --settings /absolute/path/to/mcp.json
node install.js --client cursor --settings /absolute/path/to/mcp.json
```

## 2. Hosted remote examples

- `remote.generic.mcp.json`
- `mcp-remote.generic.mcp.json`
- `codex-chatgpt-agent.remote-bridge.mcp.json`

หมายเหตุ:

- remote example ใช้ `url` ไปยัง hosted Streamable HTTP endpoint เช่น `https://mcp.example.com/mcp`
- header `Authorization` ในตัวอย่างนี้คือ public client auth ที่ service เดิมรับตรงได้ผ่าน `MCP_REMOTE_BEARER_TOKEN(S)`
- อย่าส่ง internal headers อย่าง `x-mcp-authenticated-user` หรือ `x-mcp-proxy-secret` จาก client ตรง ๆ ยกเว้นคุณกำลังใช้ legacy trusted-proxy integration ภายใน
- repo นี้ verify remote mode ระดับ protocol ด้วย `npm run verify:mcp:http`; ส่วน host apps/IDE clients ที่รับ remote URL โดยตรงยังต้องดู support matrix ใน `README.md` และ `COMPATIBILITY_POLICY.md`
- ถ้า client ของคุณยังไม่ verify ว่ารับ remote MCP URL ตรง ๆ ได้ดี ให้ใช้ `mcp-remote` bridge เป็น fallback
- `mcp-remote.generic.mcp.json` เป็นตัวอย่าง bridge แบบ generic
- `codex-chatgpt-agent.remote-bridge.mcp.json` เป็นตัวอย่างที่ตั้งชื่อไฟล์ให้ตรงกับ Codex use case ของ `P8-04`
