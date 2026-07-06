# Remote HTTP Mode Contract

อัปเดตล่าสุดเมื่อ: `2026-07-05 13:35:00 +0700`

เอกสารนี้เป็น source-of-truth ของ Phase 6B สำหรับ `flutter-widget-wallet-mcp` หลังจากเปิดใช้งาน hosted Streamable HTTP mode จริงแล้ว

## สถานะปัจจุบัน

- transport ที่รองรับในโค้ดตอนนี้มี 2 แบบ:
  - local `stdio` ผ่าน [index.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/index.js)
  - hosted `streamable-http` ผ่าน [http-server.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/http-server.js)
- remote endpoint expose เฉพาะ **read-only tools** จาก registry เดิม
- remote mode ใช้ core dispatcher / tool contracts / widget catalog logic ชุดเดียวกับ `stdio`; ต่างกันเฉพาะ transport layer และ security boundary

## Use Cases ของ Remote Mode

1. external users หรือ agents ที่ต้องอ่าน widget source-of-truth โดยไม่ clone repo ทั้งก้อน
2. clients ที่เชื่อม MCP ผ่าน remote URL ได้ตรงกว่า local process
3. shared hosted endpoint ที่ต้องการ freshness contract, auditability, และ cache namespace กลาง
4. deployment channel เช่น `production` / `staging` ที่ต้อง pin กับ commit SHA ชัดเจน

## Auth Boundary

- public client สามารถ authenticate ตรงกับ MCP process ผ่าน `Authorization: Bearer ...` ได้ เมื่อ server ถูกตั้งค่า `MCP_REMOTE_BEARER_TOKEN` หรือ `MCP_REMOTE_BEARER_TOKENS`
- trusted-proxy mode เดิมยังรองรับอยู่เพื่อ backward compatibility:
  - authenticated principal ผ่าน header `x-mcp-authenticated-user` (configurable)
  - proxy shared secret ผ่าน header `x-mcp-proxy-secret` (configurable)
- remote endpoint จะ reject request ถ้าไม่มี bearer token ที่ถูกต้อง และไม่มี trusted-proxy headers ที่ถูกต้องตามค่า env
- client ภายนอกไม่ควรส่ง `x-mcp-proxy-secret` ตรง ๆ; ถ้าระบบใดยังใช้ proxy mode ให้ถือว่าเป็น internal integration path

## Read-Only Tool Boundary

- remote endpoint publish เฉพาะ tools ที่มี `readOnlyHint: true`
- write/generation tools เช่น `generate_widget_code` และ `generate_widgetbook_use_case` ไม่ถูก expose บน hosted endpoint
- ถ้า caller ยิง `tools/call` มาหา tool ที่ไม่อยู่ใน hosted registry จะถูก reject เป็น `UNKNOWN_TOOL`

## Cache Invalidation Strategy

- cache namespace ของ hosted mode ผูกกับ `repo identity + channel + commit SHA`
- implementation ใช้ `RemoteCatalogRegistry` เพื่อเก็บ active snapshot ตาม namespace แยกจาก local `stdio`
- ทุก refresh/deployment จะสร้างหรือ activate snapshot ของ namespace เป้าหมายแบบ atomic แทนการ mutate state เดิมข้าม commit
- caller ไม่สามารถ override `repo`, `repoRoot`, `branch`, หรือ `commit` ผ่าน query/header ได้

## Freshness Model

- hosted mode เป็น **snapshot of deployed clone**
- endpoint `/health` และ `/info` expose:
  - `repoIdentity`
  - `channel`
  - `commitSha`
  - `deployedAt`
  - `catalogGeneratedAt`
  - `namespace`
- contract นี้ intentionally ไม่ claim ว่าทัน uncommitted local working tree

## Branch / Commit Pinning

- remote process ถูก pin ด้วย `commitSha` ตั้งแต่ startup และ refresh จะเปลี่ยน active snapshot ตาม commit resolver ที่ deployment กำหนด
- channel เช่น `production` / `staging` ต้องแยก server name หรือ endpoint path เพื่อไม่แชร์ namespace เดียวกัน
- docs/examples ต้องระบุเสมอว่า hosted endpoint ชี้ snapshot ไหน ไม่ใช่ branch แบบลอย ๆ อย่างเดียว

## Refresh Path

- มี `POST /admin/refresh` สำหรับ manual/webhook refresh
- refresh ต้องใช้ token จาก env ผ่าน header ที่กำหนด (`x-mcp-refresh-token` โดย default)
- หลัง refresh สำเร็จ endpoint `/health` และ `/info` ต้องสะท้อน `commitSha` / `namespace` ใหม่ทันที

## Operational Notes

- `npm run start:http` ใช้เปิด hosted Streamable HTTP endpoint
- `npm run verify:mcp:http` เป็น protocol-level smoke check ของ remote mode
- `npm test` มี coverage สำหรับ auth rejection, repo pinning, refresh, rate limiting, และ contract parity เทียบกับ stdio
