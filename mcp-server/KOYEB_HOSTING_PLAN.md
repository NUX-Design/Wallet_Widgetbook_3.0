# Koyeb Hosting Plan: `flutter-widget-wallet-mcp`

สถานะ: **Proposed / Pilot pending** — ยังไม่ deploy จริง รอ validation ตามข้อ 6 ก่อน commit ใช้งานถาวร

## 1. เป้าหมาย

ให้ agent หลายตัวจากหลาย client (Claude Code, Codex, Cursor, Antigravity, Kiro) เชื่อมต่อ `flutter-widget-wallet-mcp` ได้โดยไม่ต้อง clone repo นี้ลงเครื่องตัวเอง โดยใช้ Koyeb เป็น hosting สำหรับ transport `streamable-http` ที่มีอยู่แล้วใน repo (ไม่มีการแก้โค้ด MCP server สำหรับแผนนี้)

## 2. ทำไมเลือก Koyeb

เทียบกับตัวเลือกอื่นที่พิจารณาไปแล้ว:

| ตัวเลือก | เหตุผลที่ไม่เลือกเป็นหลัก |
|---|---|
| Hostinger VPS (self-managed) | ต้องดูแล pm2/systemd/Nginx เอง, มี ops overhead สูงกว่า |
| Render | cold start ช้า (30-60s) เพราะ free tier sleep เร็ว |
| Northflank | ไม่ sleep เลยก็จริง แต่ต้องใส่บัตรเครดิต |
| Cloudflare Workers (`McpAgent`) | ต้อง refactor filesystem-based widget catalog ใหม่ทั้งหมด (Workers ไม่มี local fs) — เก็บเป็นเป้าหมายระยะยาว ไม่ใช่ตอนนี้ |
| npm publish + npx | ต้อง refactor data access ให้ดึงจาก GitHub API หรือ bundle snapshot ทุกครั้งที่ publish |
| npx ชี้ตรง GitHub subdirectory | ไม่เสถียร (npm/pnpm ยังมี open issue เรื่อง git subdir support) และไม่มี single source of truth กลาง |

**Koyeb ชนะเพราะ**: ไม่ต้องใส่บัตรเครดิต, cold start เร็วกว่า Render มาก (1-5 วิ), รองรับ monorepo subdirectory อย่างเป็นทางการผ่าน "Work directory" (deploy `mcp-server/` ตรง ๆ ได้โดยไม่ต้อง hack), ไม่ต้องแก้โค้ดใด ๆ ใน repo

**ความเสี่ยงที่ยังไม่ยืนยัน**: free tier ของ Koyeb ระบุว่าบล็อก held connection (websocket/HTTP2 stream) จาก internet เข้า service — MCP `StreamableHTTPServerTransport` อาจต้องพึ่ง SSE-style held connection สำหรับ server-to-client notification ในบางกรณี ต้อง pilot test ก่อนใช้จริง (ดูข้อ 6)

## 3. Deploy Configuration

| ค่า | Setting |
|---|---|
| Source | GitHub repo นี้, branch `main` |
| Work directory | `mcp-server` |
| Build command | `npm ci` |
| Start command | `node http-server.js` |
| Health check | HTTP protocol, path `/health` |
| Instance | Free (512MB RAM / 0.1 vCPU) |
| Env vars | `MCP_REMOTE_HOST=0.0.0.0`, `MCP_REMOTE_PORT=<Koyeb-assigned PORT>`, `MCP_REMOTE_PROXY_SHARED_SECRET`, `MCP_REMOTE_REFRESH_TOKEN`, `MCP_REMOTE_CHANNEL=production`, `MCP_REMOTE_COMMIT_SHA` |
| Auto-deploy | เปิดไว้ — push เข้า `main` แล้ว Koyeb build/redeploy ให้เองอัตโนมัติ |

## 4. Domain / TLS

- Cloudflare DNS: CNAME `mcp.yourdomain.com` → Koyeb-assigned hostname
- Koyeb custom domain (ฟรี สูงสุด 10 domains) ผูก TLS ให้อัตโนมัติ
- Optional: เปิด Cloudflare Access / Zero Trust คั่นหน้า subdomain นี้เพื่อเพิ่ม auth layer ก่อนถึง Koyeb

## 5. Client Access Pattern

ใช้ config เดียวกันแจกให้ทุก client ผ่าน `mcp-remote` bridge (แทนการพึ่ง native remote-URL support ของแต่ละ client ที่ไม่เท่ากัน):

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp": {
      "command": "npx",
      "args": ["mcp-remote", "https://mcp.yourdomain.com/mcp", "--header", "Authorization: Bearer <TOKEN>"]
    }
  }
}
```

เหตุผล: ทุก client ที่กล่าวถึงรองรับ local stdio command เหมือนกันหมด ไม่ต้องเช็คทีละตัวว่า native remote-URL support ผ่านจริงหรือ best-effort (ตาม `COMPATIBILITY_POLICY.md` Codex remote-URL ตรงยังเป็น best-effort/unverified)

## 6. Validation Checklist ก่อน commit ใช้จริง

1. Deploy pilot ขึ้น Koyeb ตามข้อ 3
2. รัน `cd mcp-server && npm run verify:mcp:http` ชี้ไปที่ URL Koyeb แทน localhost
3. เช็คว่าผ่านครบ: `tools/list`, `list_widgets`, `search_widgets`, `get_widget_metadata`, `/info`, `/admin/refresh`, `/health`
4. ทดสอบ `mcp-remote` bridge จริงกับ client อย่างน้อย 1 ตัว (แนะนำ Codex ก่อน เพราะกังวลเรื่อง remote support มากสุด)
5. ถ้า fail เพราะ held-connection restriction → สลับไป Northflank (fallback ตามข้อ 2)

## 7. Out of Scope (ตอนนี้)

- Refactor ไป Cloudflare Workers/`McpAgent` — เป้าหมายระยะยาว ไม่ใช่แผนนี้
- Publish `mcp-server` เป็น npm package — ไม่จำเป็นเพราะ `mcp-remote` แก้ปัญหา multi-client ได้แล้ว

## 8. เอกสารที่เกี่ยวข้อง

- [REMOTE_MODE_DECISION.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/REMOTE_MODE_DECISION.md) — auth boundary/freshness/cache design ที่แผนนี้ยึดตาม
- [COMPATIBILITY_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/COMPATIBILITY_POLICY.md) — client support matrix
- [README.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/README.md) — hosted remote onboarding เดิม (local VPS-based instructions)
- [task/TASKS.md](/Users/Niwat.yah/flutter_widgetbook_3.0/task/TASKS.md) — execution checklist ของแผนนี้ (Phase 8)
