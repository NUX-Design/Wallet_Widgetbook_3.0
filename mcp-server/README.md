# flutter-widget-wallet-mcp

This directory contains the single Model Context Protocol (MCP) server for the Wi_Wallet Design System and widget library. It allows AI-powered coding assistants to search widgets, inspect metadata, extract Flutter source code, and follow design-system implementation rules.

## 🧭 เลือกวิธีติดตั้ง: Local `stdio` vs Hosted Remote

มี 2 ทางเลือกสำหรับให้ agent ภายนอก (เช่น Claude Code, Codex, Cursor) เชื่อมต่อ MCP นี้ เลือกทางที่เหมาะกับสถานการณ์ของคุณ:

| | ทางเลือกที่ 1: Local `stdio` | ทางเลือกที่ 2: Hosted Remote (`streamable-http`) |
|---|---|---|
| ต้อง clone repo ไหม | ต้อง clone ลงเครื่องตัวเอง | ไม่ต้อง clone — เชื่อมผ่าน URL อย่างเดียว |
| ใครเหมาะ | maintainer / dev ที่ต้อง debug กับ working tree จริง | external user / agent อื่นที่แค่อยากอ่าน widget catalog |
| ความสดของข้อมูล | ตรงกับ working tree ล่าสุดบนเครื่องนั้นทันที | เป็น snapshot ของ commit ที่ deploy ไว้ (ดู `/health`, `/info`) |
| สถานะ Codex | **officially supported** (verify ผ่าน `npm run validate:onboarding`) | **best-effort / unverified** ในโหมด remote URL โดยตรง |
| ตั้งค่ายังไง | ดูหัวข้อ [🚀 Team Installation (Automated)](#-team-installation-automated) ด้านล่าง | ดูหัวข้อ [🌐 Hosted Remote Onboarding](#-hosted-remote-onboarding) ด้านล่าง |

**สรุปสั้น**: ถ้าอยากได้ความน่าเชื่อถือสูงสุดกับ Codex ให้ใช้ทาง **local stdio** เพราะเป็นทางเดียวที่ verify กับ Codex จริงตาม Client Support Matrix ด้านล่าง ส่วน remote เหมาะกับ client ที่รองรับ Streamable HTTP โดยตรง (เช่น MCP SDK clients) หรือกรณีไม่อยากให้ external user clone repo ทั้งก้อน

## 🚀 Team Installation (Automated)

We have provided a script to automatically configure your local development environment. This will register the MCP server with correctly resolved absolute paths for your specific machine.

### Prerequisites

- **Node.js**: Version 18 or higher.
- **Project Cloned**: Ensure you have this project repository on your local machine.

### Installation Steps

1. **Open your terminal** and navigate to this directory:
   ```bash
   cd mcp-server
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Generate config examples or install into an existing client config**:
   ```bash
   npm run install-mcp
   ```

   คำสั่งนี้จะ regenerate:
   - `mcp.json.example`
   - `examples/claude-code.mcp.json`
   - `examples/codex-chatgpt-agent.mcp.json`
   - `examples/cursor.mcp.json`

   To write directly into a client config:
   ```bash
   node install.js --client claude-code --settings /absolute/path/to/mcp.json
   node install.js --client codex-chatgpt-agent --settings /absolute/path/to/mcp.json
   node install.js --client cursor --settings /absolute/path/to/mcp.json
   ```

   Useful flags:
   - `--repo-root /absolute/path/to/repo`
   - `--server-name custom-server-name`
   - `--example-dir /absolute/path/to/output/examples`

4. **Restart your IDE**: After the script finishes successfully, restart Antigravity (or your IDE) to activate the server.

---

## 🛠 Manual Configuration (If needed)

If you prefer to configure it manually, add the following to your MCP config file:

```json
"flutter-widget-wallet-mcp": {
  "command": "node",
  "args": [
    "/ABSOLUTE/PATH/TO/PROJECT/mcp-server/index.js"
  ]
}
```

Client-specific templates:

- [claude-code.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/claude-code.mcp.json)
- [codex-chatgpt-agent.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/codex-chatgpt-agent.mcp.json)
- [cursor.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/cursor.mcp.json)
- [remote.generic.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/remote.generic.mcp.json)
- [mcp-remote.generic.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/mcp-remote.generic.mcp.json)
- [codex-chatgpt-agent.remote-bridge.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/codex-chatgpt-agent.remote-bridge.mcp.json)
- [examples/README.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/README.md)

## 🌐 Hosted Remote Onboarding

ถ้าต้องการให้ external users หรือ agents ใช้งาน MCP นี้แบบ **zero-clone** ให้ deploy `streamable-http` entrypoint แล้วแจก remote URL แทน local path

สำหรับ desktop clients อย่าง Codex / Claude Code / Cursor:

- ถ้า client รับ remote MCP URL ตรง ๆ ได้และคุณ verify เองแล้ว สามารถใช้ remote URL flow ตรงได้
- ถ้ายังไม่เคย verify host app นั้นกับ remote URL flow มาก่อน ให้ใช้ `mcp-remote` bridge เป็นค่าเริ่มต้นก่อน เพราะเป็นเส้นทาง onboarding ที่ predictable กว่าใน `P8-04`

### Start hosted endpoint

```bash
cd mcp-server
MCP_REMOTE_PROXY_SHARED_SECRET=change-me \
MCP_REMOTE_REFRESH_TOKEN=change-refresh-token \
npm run start:http
```

ค่า env สำคัญ:

- `MCP_REMOTE_PROXY_SHARED_SECRET`: shared secret ระหว่าง reverse proxy กับ MCP process
- `MCP_REMOTE_REFRESH_TOKEN`: token สำหรับ `POST /admin/refresh`
- `MCP_REMOTE_CHANNEL`: rollout channel เช่น `production` หรือ `staging`
- `MCP_REMOTE_COMMIT_SHA`: pin endpoint ให้ชี้ commit ที่ deploy อยู่
- `MCP_REMOTE_DEPLOYED_AT`: เวลาที่ snapshot นี้ถูก deploy

### Public edge proxy for real external onboarding

ถ้าต้องการให้ external clients ใช้งานผ่าน Render แบบ public จริง ให้ deploy `edge-proxy.js` เป็น web service แยกอีกตัวหนึ่ง แล้วให้ client ยิงเข้า proxy ตัวนี้แทนการยิง `flutter-widget-wallet-mcp.onrender.com` ตรง ๆ

env vars ของ edge proxy:

- `MCP_EDGE_HOST=0.0.0.0`
- `MCP_EDGE_PORT=10000`
- `MCP_EDGE_UPSTREAM_BASE_URL=https://flutter-widget-wallet-mcp.onrender.com`
- `MCP_EDGE_AUTHENTICATED_USER=external-client`
- `MCP_EDGE_BEARER_TOKEN` หรือ `MCP_EDGE_BEARER_TOKENS` = public bearer token ที่จะแจก client
- `MCP_EDGE_UPSTREAM_PROXY_SHARED_SECRET` = ค่าเดียวกับ `MCP_REMOTE_PROXY_SHARED_SECRET` ของ service MCP หลัก

Blueprint ที่ repo root ตอนนี้มี service นี้ให้แล้วในชื่อ `flutter-widget-wallet-mcp-edge`

### Public client flow

1. client เชื่อมไปที่ hosted endpoint เช่น `https://mcp.example.com/mcp`
2. client authenticate กับ reverse proxy / API gateway ของคุณ
3. proxy validate token แล้ว inject internal headers ให้ MCP process:
   - `x-mcp-authenticated-user`
   - `x-mcp-proxy-secret`

หมายเหตุ:

- remote endpoint เป็น **snapshot of deployed clone** ไม่ใช่ live local working tree
- caller ไม่สามารถ override `repo`, `branch`, หรือ `commit` ผ่าน request ได้
- remote endpoint expose เฉพาะ read-only tools
- สำหรับการทดลอง `P8-04` บนเครื่อง local ก่อนมี proxy จริงใน production สามารถใช้ dev helper ได้ด้วย `npm run start:dev-edge-proxy` แล้วตั้งค่า env vars `DEV_EDGE_PROXY_TARGET`, `DEV_EDGE_PROXY_BEARER_TOKEN`, และ `DEV_EDGE_PROXY_SHARED_SECRET`

### Remote config examples

ใช้ได้ 2 แบบ:

1. direct remote URL
2. `mcp-remote` bridge

ตัวอย่างไฟล์:

- direct remote URL: [remote.generic.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/remote.generic.mcp.json)
- generic `mcp-remote` bridge: [mcp-remote.generic.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/mcp-remote.generic.mcp.json)
- Codex-focused bridge example: [codex-chatgpt-agent.remote-bridge.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/codex-chatgpt-agent.remote-bridge.mcp.json)

ตัวอย่าง bridge command:

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp-remote": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://mcp.example.com/mcp",
        "--header",
        "Authorization: Bearer <EDGE_ACCESS_TOKEN>"
      ]
    }
  }
}
```

หมายเหตุ:

- `Authorization` เป็น edge-facing auth ระหว่าง client กับ proxy/API gateway ของคุณ
- ห้ามแจก `x-mcp-proxy-secret` ให้ client ภายนอกโดยตรง
- ถ้ากำลังทำ onboarding ให้ Codex เป็น client แรก แนะนำให้เริ่มจาก bridge example ก่อน แล้วค่อยพิจารณา native remote URL flow ภายหลัง
- ถ้าต้องการ production external path บน Render จริง ให้ใช้ URL ของ edge proxy service เช่น `https://flutter-widget-wallet-mcp-edge.onrender.com/mcp` แทน URL ของ MCP core โดยตรง

### Health / freshness surface

- `GET /health`: status + `repoIdentity` + `channel` + `commitSha` + `deployedAt`
- `GET /info`: tool registry + auth boundary summary + freshness metadata
- `POST /admin/refresh`: manual/webhook refresh ด้วย `x-mcp-refresh-token`

## 📚 Features

- **Project Info**: High-level overview of the Wi_Wallet design system.
- **Design Tokens**: Direct access to themed colors and styles.
- **Widget Catalog**: Searchable widget inventory by category, tag, and keyword.
- **Widget Metadata**: Props, dependencies, assets, preview paths, doc files, Figma links, and last update time.
- **Metadata Confidence Signals**: `get_widget_metadata` now returns source/fallback hints plus warnings when previews/docs/props drift from live code.
- **Source Extraction**: Full base widget Dart code and preview/demo code for reuse in other Flutter projects.
- **Implementation Rules**: Best practices for layout, styling, localization, and Widgetbook generation.
- **Structured MCP Output**: Tool responses now include structured output schemas and read-only annotations for better agent interoperability.

## Tool Groups

- **Design system / Figma workflows**
  - `get_design_system_info`
  - `get_color_token`
  - `get_flutter_widget_template`
  - `get_codebase_patterns`
  - `get_figma_to_flutter_mapping`
  - `generate_widget_code`
  - `generate_widgetbook_use_case`

- **Widget library discovery / extraction**
  - `list_categories`
  - `list_widgets`
  - `search_widgets`
  - `get_widget_details`
  - `get_widget_metadata`
  - `get_widget_code`
  - `get_widget_preview`

## Contract Reference

### Standard Success Shape

- ทุก tool ที่สำเร็จจะคืน `structuredContent` เป็น object ตาม `outputSchema`
- read-only tools ทุกตัวมี MCP annotations ชุดเดียวกัน: `readOnlyHint: true`, `destructiveHint: false`, `idempotentHint: true`, `openWorldHint: false`

### Standard Error Shape

- ทุก error จะคืน `content[0].text` เป็น JSON รูปแบบนี้ และตั้ง `isError: true`
- หมายเหตุ: current MCP SDK path นี้ตรวจ `structuredContent` เทียบกับ `outputSchema` เฉพาะ success payload ดังนั้น error payload แบบ JSON จะถูกส่งผ่าน text content เพื่อคง contract ให้ predictable และไม่ชน schema validator

```json
{
  "ok": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Widget \"Foo\" was not found.",
    "hint": "Use \"list_widgets\" or \"search_widgets\" first.",
    "details": {
      "widgetName": "Foo"
    }
  }
}
```

- error codes ที่ใช้ปัจจุบัน:
  - `INVALID_ARGUMENT`
  - `NOT_FOUND`
  - `EMPTY_RESULT`
  - `MISSING_RESOURCE`
  - `UNKNOWN_TOOL`
  - `INTERNAL_ERROR`

### Paginated Widget Discovery Tools

- `list_widgets(category?, limit?, offset?)`
- `search_widgets(query, limit?, offset?)`

สอง tools นี้ใช้ output shape เดียวกัน:

```json
{
  "category": "drawer",
  "total": 6,
  "count": 2,
  "limit": 2,
  "offset": 0,
  "hasMore": true,
  "widgets": [
    {
      "name": "DrawerBalanceDetail",
      "category": "drawer",
      "widgetFile": "lib/widgets/drawer/drawer_balance_detail.dart",
      "previewFiles": [
        "lib/widgets/drawer/preview_drawer_balance_detail.dart"
      ],
      "tags": ["balance", "detail", "drawer"],
      "updatedAt": "2026-06-25T03:12:00.000Z"
    }
  ]
}
```

หมายเหตุ:
- `list_widgets` จะคืน field บริบทชื่อ `category`
- `search_widgets` จะคืน field บริบทชื่อ `query`

### Minimum Output Examples

- `get_widget_metadata(widgetName)` จะคืน metadata เต็มของ widget รวม `props`, `dependencies`, `internalImports`, `assets`, `previewFiles`, `docFiles`, `figmaLinks`, `updatedAt`
- `get_widget_code(widgetName)` จะคืน `{ widgetName, widgetFile, code }`
- `get_widget_preview(widgetName)` จะคืน `{ widgetName, previews: [{ file, code }] }`

## 💻 Development

To run the server in developer mode for debugging:

```bash
node index.js
```

The server uses Standard Input/Output (stdio) for communication.

To run the hosted Streamable HTTP transport:

```bash
node http-server.js
```

## Remote HTTP Status

- transport ที่รองรับจริงตอนนี้มีทั้ง local `stdio` และ hosted `streamable-http`
- remote endpoint reuse tool contracts / dispatcher / widget catalog logic ชุดเดียวกับ `stdio`
- remote endpoint expose เฉพาะ read-only tools และ pin กับ deployed snapshot ตาม `repoIdentity + channel + commitSha`
- contract ของ hosted mode ดูต่อได้ที่ [REMOTE_MODE_DECISION.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/REMOTE_MODE_DECISION.md)

## Client Support Matrix

- Local `stdio` officially supported: Claude Code, Codex, Cursor
- Remote `streamable-http` officially supported: MCP SDK clients ที่ใช้ `StreamableHTTPClientTransport`, และ generic remote-URL clients ตาม [remote.generic.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/remote.generic.mcp.json)
- Remote best-effort / unverified: Claude Code, Codex, Cursor ในโหมด remote URL โดยตรง
- Recommended onboarding path สำหรับ desktop hosts ที่ยังไม่ verify remote URL flow: `mcp-remote` bridge ตาม [mcp-remote.generic.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/mcp-remote.generic.mcp.json) หรือ [codex-chatgpt-agent.remote-bridge.mcp.json](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/examples/codex-chatgpt-agent.remote-bridge.mcp.json)

## Operations Docs

- [RELEASE_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/RELEASE_POLICY.md)
- [CHANGELOG.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/CHANGELOG.md)
- [COMPATIBILITY_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/COMPATIBILITY_POLICY.md)
- [TROUBLESHOOTING.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/TROUBLESHOOTING.md)
- [MAINTENANCE_TH.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/MAINTENANCE_TH.md)

### Test Commands

```bash
npm test
```

Snapshot refresh when the contract intentionally changes:

```bash
npm run test:update-snapshots
```

Inspector verification for the local stdio server:

```bash
npm run verify:mcp
```

Protocol-level verification for the hosted Streamable HTTP server (spins up a local instance and tests against itself):

```bash
npm run verify:mcp:http
```

Protocol-level verification against a REAL hosted endpoint you already deployed (e.g. a Render pilot URL — see `RENDER_HOSTING_PLAN.md` and `task/TASKS.md` Phase 8):

```bash
MCP_REMOTE_BASE_URL="https://<your-host>/mcp" \
MCP_REMOTE_PROXY_SHARED_SECRET="<same-secret-as-deploy>" \
MCP_REMOTE_REFRESH_TOKEN="<same-refresh-token>" \
npm run verify:mcp:remote
```

Structured evaluation suite runner:

```bash
npm run evaluate:mcp
```

Full local parity workflow used by CI:

```bash
npm run ci:mcp
```

Onboarding validation runner:

```bash
npm run validate:onboarding
```

Runtime observability:

```bash
MCP_LOG_LEVEL=debug node index.js
```

หรือสำหรับ hosted mode:

```bash
MCP_LOG_LEVEL=debug node http-server.js
```

- log levels ที่รองรับ: `silent`, `error`, `warn`, `info`, `debug`
- log format เป็น JSON lines ทาง stderr เพื่อให้ parse หรือ redirect ต่อได้ง่าย

- `mcp-server/tests/fixtures/widget_repo/` เป็น isolated fixture repo สำหรับ parser + integration coverage
- `mcp-server/tests/helpers/tool_harness.js` เป็น integration helper สำหรับเรียก tool calls ตรงผ่าน dispatcher เดียวกับ server จริง
- ถ้า schema/output เปลี่ยนโดยตั้งใจ ให้รัน snapshot update แล้ว review diff ของไฟล์ใน `mcp-server/tests/snapshots/` ก่อน commit

### Verification Workflow

- `npm run verify:mcp` จะรัน local stdio server ผ่าน Inspector CLI แล้วตรวจซ้ำอย่างน้อย:
  - `tools/list`
  - `list_widgets`
  - `search_widgets`
  - `get_widget_metadata`
  - `get_widget_code`
  - `get_widget_preview`
- script นี้ใช้ path ที่เชื่อถือได้ของ Inspector CLI คือ `node node_modules/@modelcontextprotocol/inspector-cli/build/index.js ...` แทน packaged entrypoint เพราะ version `0.22.0` เคยมีปัญหากับ CLI wrapper
- `npm run verify:mcp:http` จะเปิด hosted Streamable HTTP endpoint แบบ local ชั่วคราว แล้วตรวจ:
  - remote read-only tool registry
  - `list_widgets`
  - `search_widgets`
  - `get_widget_metadata`
  - `/info`
  - `/admin/refresh` + `/health`
- `npm run verify:mcp:remote` ตรวจ endpoint ที่ deploy จริงแล้ว (เช่น Render pilot URL) ผ่าน `MCP_REMOTE_BASE_URL` โดยไม่ spin up server ใหม่ — ใช้สำหรับ `task/TASKS.md` P8-02 โดยเฉพาะ เพราะ `verify:mcp:http` ทดสอบกับ instance ที่มันสร้างขึ้นเองเท่านั้น ไม่สามารถชี้ออกไปยัง URL ภายนอกได้
  - ทุก request มี timeout (`MCP_REMOTE_TIMEOUT_MS`, default 15000ms) — ถ้า timeout อาจเป็น Render free-tier cold start (spin-up ใช้เวลาประมาณ 1 นาทีหลัง idle 15 นาทีตาม `render.com/docs/free`) แทนที่จะเป็น held-connection restriction จริง ดู `RENDER_HOSTING_PLAN.md` ข้อ 2/7
  - `/admin/refresh` จะถูกทดสอบเฉพาะเมื่อส่ง `MCP_REMOTE_REFRESH_TOKEN` มาด้วย (เพราะมัน mutate state จริงบน endpoint ที่ deploy อยู่)
- ถ้า command นี้ fail:
  - เช็กก่อนว่า `npm install` ถูกเรียกใน `mcp-server/`
  - เช็กว่า `docs/schema.json` และ `lib/config/themes/theme.json` ยังมีอยู่ใน repo root
  - อ่านข้อความ error จาก script เพื่อดูว่า fail ตอน `tools/list`, contract field ไหนหาย, หรือ tool call ไหนคืนผลไม่ตรง expected shape

### CI Parity And Pre-PR Checklist

- CI ฝั่ง MCP ใช้ workflow ที่ [mcp-ci.yml](/Users/Niwat.yah/flutter_widgetbook_3.0/.github/workflows/mcp-ci.yml)
- workflow นี้รัน command เดียวกับที่นักพัฒนาควรรันในเครื่อง:

```bash
npm run ci:mcp
```

- `npm run ci:mcp` จะรันตามลำดับ:
  - `npm run check:mcp-syntax`
  - `npm test`
  - `npm run verify:mcp`
  - `npm run evaluate:mcp`
- minimum commands ก่อนเปิด PR ถ้าไม่ได้รัน `npm run ci:mcp` ทั้งก้อน:
  - `npm test`
  - `npm run verify:mcp`
  - `npm run evaluate:mcp`
  - `npm run validate:onboarding` เมื่อแก้ installer, examples, หรือ onboarding docs
- ถ้าแก้ `tool_contracts.js`, `app.js`, หรือ output shape ของ tools:
  - expected contract snapshots ใน `mcp-server/tests/snapshots/` ต้องถูกอัปเดตด้วย
  - ถ้าไม่อัปเดต snapshot ให้ตรง CI จะ fail ที่ `npm test`
- ถ้าแก้ workflow หรือ scripts ให้ถือว่า `npm run ci:mcp` เป็น source of truth สำหรับ local parity เสมอ และอย่าทำให้ลำดับคำสั่งใน CI แยกจาก command นี้

### Client Distribution And Onboarding

- installer ตอนนี้รองรับ client targets หลัก:
  - `claude-code`
  - `codex-chatgpt-agent`
  - `cursor`
- ถ้าไม่ระบุ `--client` script จะ generate examples สำหรับทุก target พร้อม `mcp.json.example`
- `--repo-root` ใช้ระบุตำแหน่ง repo clone ชัดเจนเมื่อไม่รันจาก default path
- settings file ที่เป็นไฟล์ว่างจะถูก treat เป็น `{}` และ merge `mcpServers` ให้โดยอัตโนมัติ
- settings file ที่เป็น malformed JSON จะ fail พร้อมข้อความ error ชัดเจน
- onboarding flow ปัจจุบัน validate ได้ด้วย:

```bash
npm run validate:onboarding
```

- command นี้จะ smoke test flow สำหรับ Claude Code, Codex, และ Cursor โดยเขียน temp config files และตรวจ malformed-config guard

### Evaluation Suite

- evaluation suite อยู่ที่ [mcp-server/evaluations/flutter-widget-wallet-mcp-evaluation.xml](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/evaluations/flutter-widget-wallet-mcp-evaluation.xml)
- file นี้เป็น structured XML cases ที่ระบุ `tool`, `args`, และ `assert` แบบ machine-runnable เพื่อให้รันซ้ำได้ทั้งบนเครื่อง developer และใน CI
- `npm run evaluate:mcp` จะรัน suite ปัจจุบันกับ dispatcher ของ server โดยตรง
- cases ปัจจุบันครอบ:
  - category lookup
  - search
  - metadata asset lookup
  - Figma mapping
  - source extraction
  - preview extraction
  - token lookup
- ถ้า schema หรือ behavior เปลี่ยนโดยตั้งใจ ให้แก้ XML suite พร้อม expected assertions ใน commit เดียวกัน

Widget-library indexing is filesystem-driven with a short in-memory cache. It reads:

- `lib/widgets/**` for base widgets, adjacent previews, and local markdown docs
- `lib/previews/**` as a fallback preview location
- git history for `updatedAt` when available, otherwise file modification time

## Phase 2 Parser Notes

- Filesystem discovery, Dart parsing, markdown/doc enrichment, and search ranking now live in separate modules under `mcp-server/catalog/`
- Widget discovery is no longer filename-only:
  - preview candidates still accept `preview_*.dart` and `*_preview.dart`
  - files with `main()` + app/preview entrypoint patterns are also treated as preview/demo files
  - preview-to-widget matching combines filename, imported widget path, same-folder proximity, and widget-name mentions inside preview content
- Metadata precedence now follows `code > widget-local docs > broader docs/schema`
- `get_widget_metadata` exposes:
  - `metadataSources` to show where each field came from
  - `metadataConfidence` to show `low` / `medium` / `high`
  - `warnings` for stale docs, missing previews/docs, and `updatedAt` fallback to mtime

## Parser Depth Decision

- Current decision: keep the parser regex/filesystem-driven for now
- Reason:
  - the repo has stable folder conventions around `lib/widgets/<category>/`
  - nearby markdown docs already carry meaningful metadata that regex extraction can merge cheaply
  - adding analyzer-backed parsing before Phase 3 tests would increase complexity without enough guardrails
- Revisit triggers:
  - constructor/property extraction misses important widgets repeatedly
  - preview/doc matching becomes noisy across multiple folders
  - search quality regresses because regex-derived fields are too weak
