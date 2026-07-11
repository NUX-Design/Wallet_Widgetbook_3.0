# V3 Change Boundary Review Checklist

ใช้ checklist นี้กับ PR/commit ที่เพิ่มหรือแก้ Theme V3, Widget V3, MCP V3 หรือ Skills V3

## Automated gate

```bash
npm run check:v3-boundaries
npm run test:v3-boundaries
```

เมื่อ review diff เทียบกับ base branch โดยตรง:

```bash
npm run check:v3-boundaries -- --base-ref origin/main
```

Automated gate ต้องยืนยันว่า:

- `lib/config/themes/v3/**` ไม่ import `lib/config/themes/theme_color.dart` และไม่เรียก `ThemeColors.get()`
- widget เดิมใต้ `lib/widgets/**` ซึ่งอยู่นอก `lib/widgets/v3/**` ไม่ import Theme V3 หรือ Widget V3
- เมื่อ diff มีงาน V3 จะไม่มีไฟล์ใต้ `skills/**` เดิมถูกแก้; Skills V3 ต้องอยู่ใต้ `skills-v3/**`

## Frozen legacy boundaries

- [ ] ไม่เปลี่ยน behavior ของ `lib/config/themes/theme.json`
- [ ] ไม่เปลี่ยน behavior ของ `lib/config/themes/theme_color.dart`
- [ ] ไม่เปลี่ยน behavior ของ `lib/config/themes/theme_generator.dart`
- [ ] ไม่เปลี่ยน behavior ของ `lib/config/themes/base_theme.dart`
- [ ] ไม่เปลี่ยน behavior ของ `lib/config/themes/theme_constants.dart`
- [ ] ไม่ migrate หรือแก้ widget เดิมเพื่อให้พึ่งพา V3
- [ ] ไม่แก้ skill เดิมใต้ `skills/**`; เพิ่มเฉพาะ `skills-v3/**`

## Additive-only MCP integration files

ไฟล์ integration เดิมต่อไปนี้แก้ได้เฉพาะส่วนที่จำเป็นต่อการ register, route, verify หรือ deploy V3 แบบ additive:

- `mcp-server/app.js`
- `mcp-server/tool_contracts.js`
- `mcp-server/remote_support.js`
- `mcp-server/http-server.js`
- `mcp-server/scripts/verify-mcp.js`
- `mcp-server/scripts/verify-http.js`
- `mcp-server/scripts/verify-remote.js`
- `mcp-server/package.json`
- `mcp-server/package-lock.json`
- `.github/workflows/mcp-ci.yml`
- `render.yaml`

Reviewer ต้องยืนยันว่า:

- [ ] V3 implementation หลักอยู่ใต้ `mcp-server/v3/**` และ tests อยู่ใต้ `mcp-server/tests/v3/**`
- [ ] การแก้ integration files เพิ่มเฉพาะ V3 imports, registration, routing, verification หรือ deploy scope
- [ ] ชื่อ, required arguments, response fields, response types และ error semantics ของ legacy tools ไม่เปลี่ยน
- [ ] `get_color_token` ยังอ่าน legacy theme source และไม่ route ไป V3
- [ ] V3 tools มีชื่อ `v3` ชัดเจน, เป็น read-only และอ่านเฉพาะ V3 paths
- [ ] Remote registry ยัง exclude generation/write tools
- [ ] Legacy contract snapshot และ MCP integration tests ผ่านโดยไม่มี snapshot update ที่ไม่เกี่ยวข้อง

## Required regression evidence

- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `cd mcp-server && npm run check:mcp-syntax`
- [ ] `cd mcp-server && npm test`
- [ ] `cd mcp-server && npm run verify:mcp`
- [ ] `cd mcp-server && npm run verify:mcp:http`
