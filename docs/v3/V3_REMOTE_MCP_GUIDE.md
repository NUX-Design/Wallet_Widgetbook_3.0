# V3 Remote MCP Guide

สร้างเมื่อ: `2026-07-11`

คู่มือ onboarding สำหรับใช้ Theme V3 / Widget V3 tools ผ่าน hosted MCP endpoint เดิมบน Render. เอกสารนี้เป็นผลลัพธ์ปิด pilot ของ `task/V3_THEME_MCP_SKILLS_TASKS.md` (Phase 7, `V3-25`).

## สรุปสั้น

- **URL และ Bearer token mechanism เดิมใช้ได้กับทั้ง legacy และ V3** ไม่มี service, URL, หรือ auth ชุดใหม่
- Endpoint เดียวกัน expose ทั้ง legacy tools และ V3 read-only tools
- Generation/write tools ทั้ง legacy และ V3 ยังคงถูก exclude จาก remote endpoint

## Endpoint และ Auth

```text
Service:      flutter-widget-wallet-mcp
URL:          https://flutter-widget-wallet-mcp.onrender.com
MCP endpoint: https://flutter-widget-wallet-mcp.onrender.com/mcp
Transport:    streamable-http
Auth:         Authorization: Bearer <TOKEN>   (direct bearer, primary path)
```

Client config (เหมือน legacy ทุกประการ ไม่ต้องเปลี่ยน):

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

- `<TOKEN>` ต้องตรงกับ `MCP_REMOTE_BEARER_TOKEN(S)` ที่ตั้งไว้ใน Render Dashboard เท่านั้น ห้าม commit token ลงไฟล์ใดๆ
- Unauthenticated request ไปที่ `/mcp` จะถูก reject ด้วย `HTTP 401`
- `/health` และ `/info` อ่านได้แบบ anonymous สำหรับตรวจสถานะและ freshness
- `mcp-remote` bridge examples ใน `mcp-server/examples/` ยังใช้ได้เป็น fallback สำหรับ host app ที่ต่อ native remote URL ไม่ได้

## Tool Routing: Legacy vs V3

Endpoint เดียวกัน expose **27 read-only tools** = 12 legacy + 15 V3.

| กลุ่ม | ตัวอย่าง tools | Theme source |
|-------|---------------|--------------|
| Legacy | `get_color_token`, `list_widgets`, `search_widgets`, `get_widget_metadata`, `get_widget_code`, `get_widget_preview`, ... | legacy `theme.json` / `ThemeColors.get()` |
| V3 | `get_v3_color_token`, `list_v3_color_tokens`, `search_v3_color_tokens`, `list_v3_widgets`, `search_v3_widgets`, `get_v3_widget_metadata`, `get_v3_widget_code`, `get_v3_widget_preview`, `audit_v3_widget`, `get_v3_design_system_info`, `list_v3_categories`, `get_v3_widget_details`, `get_v3_flutter_widget_template`, `get_v3_codebase_patterns`, `get_v3_figma_to_flutter_mapping` | `lib/config/themes/v3/**` semantic tokens + `V3ThemeScope` |

กติกาการเลือก:

- ต้องการ widget/token เดิม → ใช้ legacy tools (ชื่อไม่มี `v3`)
- ต้องการ Theme V3 / Widget V3 → ใช้ V3 tools (ชื่อมี `v3` ชัดเจน)
- V3 tools อ่านเฉพาะ V3 paths และ **ไม่ fallback ไป legacy theme**
- `get_v3_color_token` คืน Light/Dark values, primitive aliases และ `V3ThemeScope.colorsOf(context).<property>` usage

## Skills V3 กับ Remote MCP

Skills V3 (`skills-v3/codex`, `skills-v3/claude-code`, `skills-v3/kiro`) ใช้ endpoint เดียวกันนี้:

- ทุก skill route ไปยัง V3 tools เท่านั้น และทำงานเฉพาะ `lib/widgets/v3/**`
- Remote endpoint เปิดเฉพาะ read-only V3 tools ดังนั้น `generate_v3_widget_code` / `generate_v3_widgetbook_use_case` เป็น optional local/stdio optimization เท่านั้น
- บน Remote MCP: skill ดึง template/metadata/token/code/preview (read-only) แล้ว author source ใน target repo เอง ไม่ fallback ไป legacy tools
- `flutter-widget-v3-beginner` คง flow `ask → scan → summarize → confirm → execute` และไม่แก้ไฟล์ก่อนยืนยัน scope

## Verified Client Paths และ Caveats

Verified บน deployed commit `5c3f49c1bce1feed7cc32df77d41579a17930fb0` (`2026-07-11`):

- `npm run verify:mcp:remote` (legacy tools): PASS 8/8 — `/health`, `/info`, `tools/list` (27 tools), `list_widgets`, `search_widgets`, `get_widget_metadata`, `/admin/refresh` (skip)
- `npm run verify:mcp:remote:v3` (V3 tools): PASS 13/13 — session connect, `tools/list`, V3 tools exposed (15/15), generation tools excluded, `get_v3_color_token(content/primary)` = Light `#0F172A` / Dark `#FFFFFF` / aliases `slate/900`,`white`, token list/search, V3 widget list/search/metadata/code/preview, `audit_v3_widget(V3MiniButton)` = `passed: true`

Pilot widget: `V3MiniButton` (category `button`) discoverable และดึง metadata/code/preview ผ่าน V3 skill + remote MCP ได้จริง

Caveats:

- **Free-tier cold start**: หลัง idle ~15 นาที request แรกอาจใช้เวลาถึง ~1 นาที (Render free tier). เคยวัด wall time ~26s หลัง wake-up ซึ่งยอมรับได้สำหรับ agent tooling
- **Generation/write tools ไม่ถูก expose remotely** — ใช้ได้เฉพาะ local/stdio (`npm start`)
- **Freshness**: ตรวจ commit ที่ deploy จริงจาก `/health` และ `/info` (`freshness.commitSha`, `targeting.namespace`) ไม่ใช่จากไฟล์ repo
- Trusted-proxy headers (`x-mcp-authenticated-user` + `x-mcp-proxy-secret`) ยังรองรับเพื่อ backward compatibility แต่ direct Bearer เป็น primary path

## Repeatable Verification Commands

```bash
cd mcp-server

# Legacy tools
MCP_REMOTE_BASE_URL="https://flutter-widget-wallet-mcp.onrender.com/mcp" \
MCP_REMOTE_BEARER_TOKEN="<token>" \
npm run verify:mcp:remote

# V3 tools
MCP_REMOTE_BASE_URL="https://flutter-widget-wallet-mcp.onrender.com/mcp" \
MCP_REMOTE_BEARER_TOKEN="<token>" \
npm run verify:mcp:remote:v3
```

Quick freshness check (anonymous):

```bash
curl -s https://flutter-widget-wallet-mcp.onrender.com/health
curl -s https://flutter-widget-wallet-mcp.onrender.com/info
```
