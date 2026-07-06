# Claude Code Skill Pack

วางโฟลเดอร์ `.claude/` นี้ไว้ที่ root ของโปรเจกต์เป้าหมาย แล้วเปิด Claude Code จากโปรเจกต์นั้นเพื่อให้ skill ถูก discover ได้อัตโนมัติ

การเรียกใช้งาน:

- เรียกตรงด้วย `/flutter-widget-beginner`
- หรือพิมพ์โจทย์ตามธรรมชาติ แล้วให้ Claude match จาก `description` ใน `SKILL.md`

แพ็กนี้ตั้งใจทำเป็น Claude Code native:

- แต่ละ skill ใช้ `SKILL.md` เป็น source-of-truth
- ไม่มี `agents/openai.yaml`
- ให้ใช้ร่วมกับ MCP config ของ `flutter-widget-wallet-mcp` ใน `.mcp.json` หรือ config ระดับ user

รายการ skills:

- `flutter-widget-beginner`
- `flutter-widget-search`
- `flutter-widget-install`
- `flutter-widget-adapt`
- `flutter-widget-preview`
- `flutter-widget-figma-to-code`
- `flutter-widget-audit`
- `flutter-widget-upgrade`
