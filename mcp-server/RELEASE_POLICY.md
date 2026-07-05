# Release Policy

อัปเดตล่าสุดเมื่อ: `2026-07-05 00:46:00 +0700`

เอกสารนี้เป็น source-of-truth สำหรับ `P7-01` และส่วน versioning/release ของ `P7-04`

## Semantic Versioning Policy

`flutter-widget-wallet-mcp` ใช้ `SemVer`: `MAJOR.MINOR.PATCH`

- `MAJOR`: มี breaking change ต่อ MCP tool schema, installer contract, หรือ operational workflow ที่ documented client ต้องแก้ตาม
- `MINOR`: เพิ่ม capability แบบ backward-compatible เช่น tool ใหม่, metadata field ใหม่ที่ optional, docs/scripts เพิ่มเติม
- `PATCH`: แก้ bug, ปรับ docs, ปรับ observability, หรือ internal refactor ที่ไม่เปลี่ยน documented contract

## Version Source Of Truth

- `mcp-server/package.json` คือ source-of-truth ของ version
- runtime server version ต้องอิงค่าจาก `package.json` ผ่าน [server_metadata.js](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/server_metadata.js)
- ห้าม hardcode version ซ้ำในหลายไฟล์อีก

## Changelog Workflow

1. ทุก PR ที่มีผลกับ behavior, contract, scripts, หรือ docs ของ MCP ต้องเพิ่ม entry ใน [CHANGELOG.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/CHANGELOG.md) ใต้ `Unreleased`
2. ตอน release:
   - ย้าย entries จาก `Unreleased` ไปเป็น section ของ version ใหม่
   - ระบุวันที่ release เป็น `YYYY-MM-DD`
   - bump `package.json` และ `package-lock.json` ใน commit เดียวกัน
3. ถ้ามี breaking change ให้ใส่ entry ทั้งใน `Changed` หรือ `Deprecated` และอ้างอิง [COMPATIBILITY_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/COMPATIBILITY_POLICY.md)

## Release Checklist

1. อัปเดต `CHANGELOG.md`
2. ยืนยันว่า version ใน `package.json` คือ version ที่จะปล่อย
3. รัน `cd mcp-server && npm run ci:mcp`
4. รัน `cd mcp-server && npm run validate:onboarding` ถ้าแตะ installer, examples, onboarding docs, หรือ config merge logic
5. ถ้าแตะ tool contract หรือ output shape:
   - อัปเดต snapshots ใน `mcp-server/tests/snapshots/`
   - อัปเดต evaluation assertions ถ้าจำเป็น
   - อัปเดต `README.md` หรือ policy docs ที่เกี่ยวข้อง
6. ตรวจว่า examples/config docs ยังชี้ path และ client names ปัจจุบันถูกต้อง
7. commit release changes
8. ติด tag ตาม version ที่ release

## Pre-Release Gates

- ต้องไม่มี failing MCP tests
- ต้องไม่มี known breaking change ที่ยังไม่ประกาศใน changelog/policy docs
- ถ้าเพิ่ม env vars ใหม่ ต้อง documented ใน `README.md` หรือ `MAINTENANCE_TH.md`
