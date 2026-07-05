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

หมายเหตุ:

- remote example ใช้ `url` ไปยัง hosted Streamable HTTP endpoint เช่น `https://mcp.example.com/mcp`
- header `Authorization` ในตัวอย่างนี้เป็น **edge-facing auth** ระหว่าง client กับ reverse proxy/API gateway เท่านั้น
- อย่าส่ง internal headers อย่าง `x-mcp-authenticated-user` หรือ `x-mcp-proxy-secret` จาก client ตรง ๆ เพราะ header เหล่านั้นควรถูก inject โดย trusted proxy เท่านั้น
- repo นี้ verify remote mode ระดับ protocol ด้วย `npm run verify:mcp:http`; ส่วน host apps/IDE clients ที่รับ remote URL โดยตรงยังต้องดู support matrix ใน `README.md` และ `COMPATIBILITY_POLICY.md`
