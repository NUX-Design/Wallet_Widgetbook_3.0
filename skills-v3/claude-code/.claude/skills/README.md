# Claude Code Skill Pack — Skills V3

วางโฟลเดอร์ `.claude/` นี้ไว้ที่ root ของโปรเจกต์เป้าหมาย แล้วเปิด Claude Code จากโปรเจกต์นั้นเพื่อให้ skill ถูก discover ได้อัตโนมัติ

การเรียกใช้งาน:

- เรียกตรงด้วย `/flutter-widget-v3-beginner`
- หรือพิมพ์โจทย์ตามธรรมชาติ แล้วให้ Claude match จาก `description` ใน `SKILL.md`

Skills V3 ใช้ MCP server เดิม (`flutter-widget-wallet-mcp`) และเรียกเฉพาะ V3-prefixed tools (`*_v3_*`); ทำงานเฉพาะ `lib/widgets/v3/**` และห้าม migrate/overwrite widget เดิม ดู `docs/v3/V3_SKILLS_SPEC.md` สำหรับ canonical workflow และ tool routing เต็มรูปแบบ

แพ็กนี้ตั้งใจทำเป็น Claude Code native:

- แต่ละ skill ใช้ `SKILL.md` เป็น source-of-truth
- ไม่มี `agents/openai.yaml`
- ให้ใช้ร่วมกับ MCP config ของ `flutter-widget-wallet-mcp` ใน `.mcp.json` หรือ config ระดับ user (endpoint และ Bearer token เดิม)
- แพ็กนี้อยู่แยกจาก `skills/claude-code/.claude/skills/` (legacy) โดยสมบูรณ์; ไม่มีการแก้ legacy pack ใด ๆ

## Remote-safe fallback

Remote MCP เปิดเฉพาะ read-only V3 tools หาก workflow ต้องสร้าง widget หรือ Widgetbook use case ให้ skill ดึง template, metadata, tokens และ preview ผ่าน Remote MCP แล้วเขียน source ในโปรเจกต์ปลายทางเอง ส่วน `generate_v3_widget_code` และ `generate_v3_widgetbook_use_case` เป็นตัวเลือกเฉพาะ local/stdio MCP และห้าม fallback ไป legacy tools

รายการ skills:

- `flutter-widget-v3-beginner`
- `flutter-widget-v3-search`
- `flutter-widget-v3-install`
- `flutter-widget-v3-adapt`
- `flutter-widget-v3-preview`
- `flutter-widget-v3-figma-to-code`
- `flutter-widget-v3-audit`
- `flutter-widget-v3-upgrade`
