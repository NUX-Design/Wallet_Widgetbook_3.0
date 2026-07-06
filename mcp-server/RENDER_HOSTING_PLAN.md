
# Render Hosting Plan: `flutter-widget-wallet-mcp`

สถานะ: **Proposed / Pilot pending** — ยังไม่ deploy จริง รอ validation ตามข้อ 6 ก่อน commit ใช้งานถาวร

หมายเหตุ: เอกสารนี้แทนที่ [KOYEB_HOSTING_PLAN.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/KOYEB_HOSTING_PLAN.md) เป็น hosting target หลักของ Phase 8 — ดูเหตุผลในข้อ 2

## 1. เป้าหมาย

ให้ agent หลายตัวจากหลาย client (Claude Code, Codex, Cursor, Antigravity, Kiro) เชื่อมต่อ `flutter-widget-wallet-mcp` ได้โดยไม่ต้อง clone repo นี้ลงเครื่องตัวเอง โดยใช้ **Render** เป็น hosting สำหรับ transport `streamable-http` ที่มีอยู่แล้วใน repo — ไม่มีการแก้ core MCP server logic สำหรับแผนนี้ (มีแค่ config/env vars เพิ่มเพื่อให้ bind port ที่ Render คาดหวัง)

## 2. ทำไมเปลี่ยนจาก Koyeb ไปเป็น Render

### เหตุผลที่ต้องเลิกใช้ Koyeb

Koyeb ถูก Mistral AI เข้าซื้อในช่วงต้นปี 2026 และปิด free Starter tier สำหรับผู้ใช้ใหม่ทันที พร้อมย้าย roadmap ไปทาง AI inference/enterprise GPU workloads แทน standard web app hosting — แผนเดิมใน `KOYEB_HOSTING_PLAN.md` จึงใช้ไม่ได้แล้วสำหรับ use case นี้ (ต้องมี free tier จริง ไม่ใช่ trial/บัตรเครดิต)

แหล่งอ้างอิง: [Koyeb pricing FAQ](https://www.koyeb.com/docs/faq/pricing), [Best Koyeb Alternatives in 2026 — kuberns.com](https://kuberns.com/blogs/koyeb-alternatives/)

### ทำไมเลือก Render

เทียบกับตัวเลือกที่เคยพิจารณาไปแล้วใน `KOYEB_HOSTING_PLAN.md`:

| ตัวเลือก | สถานะล่าสุด |
|---|---|
| Koyeb | ปิด free tier ให้ผู้ใช้ใหม่แล้ว (หลัง Mistral AI acquisition ต้นปี 2026) — ตัดออกจากตัวเลือก |
| Hostinger VPS (self-managed) | ยังต้องดูแล pm2/systemd/Nginx เอง, ops overhead สูงกว่า — ไม่เปลี่ยนข้อสรุปเดิม |
| Northflank | ไม่ sleep เลยก็จริง แต่ต้องใส่บัตรเครดิต — ไม่เปลี่ยนข้อสรุปเดิม |
| Cloudflare Workers (`McpAgent`) | ต้อง refactor filesystem-based widget catalog ทั้งหมด — เก็บเป็นเป้าหมายระยะยาว ไม่ใช่ตอนนี้ |
| **Render** | มี free web service tier จริง (750 instance-hours/เดือน/workspace), ไม่ต้องใส่บัตรเครดิตสำหรับ free instance type, รองรับ custom domain + managed TLS ฟรีบน free tier, รองรับ monorepo ผ่าน `rootDir` อย่างเป็นทางการทั้งใน Dashboard และ Blueprint (`render.yaml`), และทีมมี **Codex CLI ที่ติดตั้ง Render plugin อยู่แล้ว** ทำให้ deploy/debug/monitor ทำผ่าน agent ได้ตรงในเทอร์มินัลโดยไม่ต้องสลับไปเปิด Dashboard เอง |

**Render ชนะเพราะ**: มี free tier ที่ยังเปิดรับผู้ใช้ใหม่จริง, ไม่ต้องผูกบัตรเครดิต, รองรับ custom domain/TLS ฟรี (Koyeb ก็รองรับส่วนนี้เหมือนกันแต่ไม่มี free tier ให้ใช้แล้ว), รองรับ monorepo subdirectory ผ่าน `rootDir` เป็นทางการ, และมี Codex plugin ที่ทำให้ deploy ง่ายกว่าทุกตัวเลือกอื่นที่เคยประเมินไว้

**ข้อแลกเปลี่ยนที่ต้องรับทราบ (เทียบกับที่ Koyeb เคยให้)**:

- Cold start ช้ากว่า Koyeb ที่เคยประเมินไว้ (1-5 วิ) — Render free web service spin down หลัง idle 15 นาที แล้วต้องใช้เวลา **ประมาณ 1 นาที** ในการ spin กลับขึ้นมาตาม [render.com/docs/free](https://render.com/docs/free) (บางแหล่งข้างนอกรายงานได้ถึง 30-60 วิ เช่น [kuberns.com](https://kuberns.com/blogs/is-render-good-for-production/)) — ยอมรับได้เพราะ use case นี้คือ agent tooling ไม่ใช่ production traffic ที่ต้อง sub-second ทุก request
- Free instance มี **750 free instance-hours ต่อ workspace ต่อเดือน** — เวลาที่ service spin down ไม่กินโควต้านี้ ดังนั้นถ้า MCP ไม่ได้ถูกเรียกถี่ตลอด 24 ชม. จะไม่ชนขีดจำกัดนี้ในทางปฏิบัติ
- Free web service มี ephemeral filesystem (state หายทุกครั้งที่ redeploy/restart/spin-down) — ไม่กระทบเราเพราะ `RemoteCatalogRegistry` เก็บ cache เป็น in-memory อยู่แล้ว ไม่มีการเขียนไฟล์ persistent
- ไม่มีความเสี่ยง held-connection ที่ยังไม่ยืนยันแบบ Koyeb — Render เองมี official tutorial สำหรับ host MCP server แบบ Streamable HTTP โดยเฉพาะ ([Build and host a full-featured, secure MCP server on Render](https://render.com/tutorials/secure-mcp-server-on-render/introduction)) ซึ่งยืนยันว่า pattern นี้ใช้งานได้จริงบน Render แต่ยังต้อง pilot test ตาม checklist ข้อ 6 อยู่ดีเพื่อความชัวร์กับ implementation ปัจจุบันของเรา

## 3. Codex Render Plugin — ทำไมมันทำให้ deploy ง่ายขึ้นจริง

ทีมมี Codex CLI ที่ติดตั้ง Render plugin แล้ว ([render.com/agents/codex](https://render.com/agents/codex)) ซึ่งให้ Codex ทำสิ่งต่อไปนี้ได้ตรงในเทอร์มินัลโดยไม่ต้องเปิด Dashboard เอง:

- อ่าน repo แล้ว propose `render.yaml` Blueprint ให้ (`render-deploy` skill)
- validate Blueprint ผ่าน Render CLI ก่อน apply จริง
- ตรวจ deploy logs และ debug deploy ที่ fail (`render-debug` skill)
- monitor service แบบ real-time (`render-monitor` skill)
- authenticate ผ่าน `RENDER_API_KEY` (Bearer token) ที่ MCP server ของ Render เอง (`mcp.render.com`) ใช้อยู่แล้ว — ไม่ต้องตั้งค่า auth ใหม่

Prompt ตัวอย่างที่ใช้กับ Codex ได้ทันที (จาก Render's own docs):

- `"Deploy this project to Render and explain the Blueprint before applying it."`
- `"Check the deploy logs for the last failed deploy and fix the error."`

**สิ่งที่ต้องเตรียมก่อนให้ Codex deploy**: `render.yaml` ที่อยู่ที่ repo root (ดูข้อ 4) ต้อง valid ก่อน — Codex/Render CLI จะ validate ให้อัตโนมัติ แต่คนใน repo ควร review ค่า `rootDir`, `envVars` ที่เป็น secret (`sync: false`) ก่อน apply จริงเสมอ เพราะ Codex ทำได้แค่ propose/apply ไม่ได้ตัดสินใจเรื่อง secret values ให้

## 4. Deploy Configuration

ใช้ Blueprint (`render.yaml` ที่ repo root — ดู [render.yaml](/Users/Niwat.yah/flutter_widgetbook_3.0/render.yaml)) แทนการตั้งค่าทีละอย่างใน Dashboard เพราะ Codex Render plugin ทำงานกับ Blueprint ได้ตรงที่สุด และ Blueprint sync จะ trigger deploy อัตโนมัติเสมอไม่ว่า build filter จะเป็นยังไง

| ค่า | Setting |
|---|---|
| Source | GitHub repo นี้, branch `main` |
| Root directory (`rootDir`) | `mcp-server` |
| Build command | `npm ci` |
| Start command | `node http-server.js` |
| Health check | HTTP path `/health` |
| Instance type | Free (750 free instance-hours/เดือน/workspace) |
| Env vars (plain) | `MCP_REMOTE_HOST=0.0.0.0`, `MCP_REMOTE_PORT=10000`, `MCP_REMOTE_CHANNEL=production` |
| Env vars (secret, `sync: false` — ตั้งค่าใน Dashboard เท่านั้น ไม่ commit ลง Blueprint) | `MCP_REMOTE_BEARER_TOKENS`, `MCP_REMOTE_PROXY_SHARED_SECRET`, `MCP_REMOTE_REFRESH_TOKEN`, `MCP_REMOTE_COMMIT_SHA` |
| Auto-deploy | `autoDeployTrigger: commit` — เมื่อตั้ง `rootDir: mcp-server` แล้ว Render จะ trigger deploy เฉพาะตอนไฟล์ใต้ `mcp-server/` เปลี่ยนเท่านั้น |

สำหรับ external onboarding จริงในแนวทางปัจจุบัน ให้ใช้ web service เดิม `flutter-widget-wallet-mcp` ตัวเดียว แล้วตั้ง `MCP_REMOTE_BEARER_TOKENS` บน service นี้ตรง ๆ เพื่อให้ public clients ส่ง `Authorization: Bearer <token>` เข้ามาได้โดยไม่ต้องมี edge service เพิ่ม

**สำคัญ — port binding**: `http-server.js` อ่าน `MCP_REMOTE_HOST` และ `MCP_REMOTE_PORT` จาก env โดยตรง ไม่ได้อ่าน Render's ตัว `PORT` ที่ inject มาให้อัตโนมัติ ดังนั้นต้องตั้งค่าทั้งสอง env var นี้เอง:

- `MCP_REMOTE_HOST=0.0.0.0` — Render's edge proxy เชื่อมต่อ process ผ่าน internal IP ไม่ใช่ loopback, ถ้า bind แค่ `127.0.0.1` (ค่า default เดิมของโค้ด) proxy จะต่อไม่ติดและ health check จะ fail
- `MCP_REMOTE_PORT=10000` — 10000 คือ default expected port ของ Render สำหรับ web service (Render เรียกมันว่า `PORT` แต่ในเมื่อโค้ดเราอ่านชื่อ env var ของเราเอง การตั้งให้ตรงกับเลข 10000 ก็เพียงพอโดยไม่ต้องแก้โค้ด)

เอกสารอ้างอิง: [render.com/tutorials/web-service-vs-static-site/web-services](https://render.com/tutorials/web-service-vs-static-site/web-services) — "Bind to 0.0.0.0 ... Listen on the port in the PORT environment variable. Render sets PORT for you, defaulting to 10000."

## 5. Domain / TLS

Render ให้ custom domain + managed TLS แบบ auto-renew ฟรีบน free web service instance type อยู่แล้ว ([render.com/docs/free](https://render.com/docs/free)) ไม่ต้องพึ่ง Cloudflare CNAME เหมือนแผน Koyeb เดิม (จะใช้ Cloudflare เพิ่มเป็น optional auth layer ก็ได้ แต่ไม่ใช่ requirement สำหรับ TLS)

ขั้นตอน:
1. Deploy service แล้วได้ URL แบบ `https://<service-name>.onrender.com` ก่อน (มี TLS ให้อัตโนมัติแล้ว ใช้ทดสอบได้ทันที)
2. ถ้าต้องการ custom domain: เพิ่ม custom domain ในหน้า service settings บน Render แล้วชี้ DNS (CNAME/ALIAS) จาก domain provider ของเราไปที่ hostname ที่ Render ให้ — Render จะ provision TLS certificate ให้อัตโนมัติหลัง DNS verify ผ่าน
3. Optional: เปิด Cloudflare Access/Zero Trust คั่นหน้า custom domain นี้เพื่อเพิ่ม auth layer ก่อนถึง Render เหมือนแผนเดิม

## 6. Client Access Pattern

ใช้ config เดียวกันแจกให้ทุก client ได้ 2 แบบ โดยให้ direct remote URL เป็นเส้นทางหลักก่อน:

แบบที่ 1: direct remote URL

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp": {
      "url": "https://flutter-widget-wallet-mcp.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer <TOKEN>"
      }
    }
  }
}
```

แบบที่ 2: `mcp-remote` bridge ถ้า host app ไหนมีปัญหากับ remote URL ตรง

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp": {
      "command": "npx",
      "args": ["mcp-remote", "https://<your-service>.onrender.com/mcp", "--header", "Authorization: Bearer <TOKEN>"]
    }
  }
}
```

แนวทางปัจจุบันของ Phase 8 คือให้ `http-server.js` รับ `Authorization: Bearer <TOKEN>` ตรงจาก external clients ได้เลยผ่าน `MCP_REMOTE_BEARER_TOKEN(S)` บน service เดิม ส่วน trusted-proxy headers (`x-mcp-authenticated-user`, `x-mcp-proxy-secret`) ยังเก็บไว้เพื่อ backward compatibility กับ integrations ภายในที่อาจมีอยู่เดิม

## 7. Validation Checklist ก่อน commit ใช้จริง

1. Deploy pilot ขึ้น Render ตามข้อ 4 — แนะนำให้ใช้ Codex + Render plugin เพื่อ propose/validate/apply `render.yaml` (ดูข้อ 3) แทนการตั้งค่าทีละอย่างใน Dashboard
2. รัน `cd mcp-server && npm run verify:mcp:remote` ชี้ไปที่ URL Render จริง (`verify:mcp:http` ใช้ตรวจ local self-host เท่านั้น)
3. เช็คว่าผ่านครบ: `tools/list`, `list_widgets`, `search_widgets`, `get_widget_metadata`, `/info`, `/admin/refresh`, `/health`
4. วัด cold-start จริงหลัง idle 15+ นาที แล้วบันทึกตัวเลขจริงเทียบกับ "ประมาณ 1 นาที" ที่ Render ประกาศไว้ — ถ้าช้ากว่าที่ยอมรับได้สำหรับ use case จริง ให้พิจารณาอัปเกรดเป็น paid instance (ไม่ sleep) แทนการเปลี่ยน provider อีกรอบ
5. ตั้ง `MCP_REMOTE_BEARER_TOKENS` บน Render service เดิม แล้วทดสอบทั้ง direct remote URL และ `mcp-remote` bridge กับ client อย่างน้อย 1 ตัว (แนะนำ Codex ก่อน เพราะเป็น target ของ `P8-04`)

## 8. Out of Scope (ตอนนี้)

- Refactor ไป Cloudflare Workers/`McpAgent` — เป้าหมายระยะยาว ไม่ใช่แผนนี้
- Publish `mcp-server` เป็น npm package — ไม่จำเป็นเพราะ `mcp-remote` แก้ปัญหา multi-client ได้แล้ว
- อัปเกรดเป็น Render paid plan ทันที — ให้ pilot บน free tier ก่อน แล้วค่อยประเมินใหม่ถ้า cold start หรือ 750-hour cap เป็นปัญหาจริงในทางปฏิบัติ

## 9. เอกสารที่เกี่ยวข้อง

- [REMOTE_MODE_DECISION.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/REMOTE_MODE_DECISION.md) — auth boundary/freshness/cache design ที่แผนนี้ยึดตาม
- [COMPATIBILITY_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/COMPATIBILITY_POLICY.md) — client support matrix
- [README.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/README.md) — hosted remote onboarding
- [render.yaml](/Users/Niwat.yah/flutter_widgetbook_3.0/render.yaml) — Blueprint ที่ใช้ deploy จริง
- [KOYEB_HOSTING_PLAN.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/KOYEB_HOSTING_PLAN.md) — แผนเดิมที่ถูกแทนที่ (เก็บไว้เป็น historical reference ว่าทำไมตัวเลือกอื่นถึงถูกตัดออกไปก่อนหน้านี้)
- [task/TASKS.md](/Users/Niwat.yah/flutter_widgetbook_3.0/task/TASKS.md) — execution checklist ของแผนนี้ (Phase 8)
