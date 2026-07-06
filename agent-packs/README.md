# Agent Packs

โฟลเดอร์นี้รวมชุดแพ็กแยกตาม agent สำหรับใช้งานกับ `flutter-widget-wallet-mcp`

## Packs

- `claude-code/`
  ใช้ native skills layout ของ Claude Code: `.claude/skills/`

- `kiro/`
  ใช้ native skills layout ของ Kiro: `.kiro/skills/`

- `cursor/`
  ใช้ fallback layout แบบ `AGENTS.md` + MCP config examples
  หมายเหตุ: ยังไม่ได้ยืนยันจาก docs ทางการที่เปิดได้ในรอบนี้ว่า Cursor รองรับ native Agent Skills pack แบบเดียวกับ Claude/Kiro

- `antigravity/`
  ใช้ fallback layout แบบ `AGENTS.md` + MCP config examples
  หมายเหตุ: ยังไม่ได้ยืนยันจาก docs ทางการที่เปิดได้ในรอบนี้ว่า Antigravity รองรับ native Agent Skills pack แบบเดียวกับ Claude/Kiro

## Recommended Usage

- ถ้าต้องการ native skills ที่ชัดเจน: ใช้ `claude-code/` หรือ `kiro/`
- ถ้าต้องการใช้งานกับ `cursor/` หรือ `antigravity/`: ใช้ `AGENTS.md` ในแพ็กนั้นร่วมกับ MCP config example
