# Antigravity Flutter Widget Agent Pack

ใช้ไฟล์นี้เป็น fallback instruction pack สำหรับ Antigravity เมื่อทำงานกับ `flutter-widget-wallet-mcp`

## Scope

ไฟล์นี้แทน native skill pack แบบชั่วคราว เพราะยังไม่ได้ยืนยันจาก docs ทางการที่เปิดได้ในรอบนี้ว่า Antigravity รองรับ `SKILL.md` pack แบบเดียวกับ Claude Code หรือ Kiro

## Required MCP

เชื่อม MCP server `flutter-widget-wallet-mcp` ก่อนใช้งาน workflow ใด ๆ

## Workflow Routing

### `flutter-widget-beginner`

ใช้เมื่อ:
- ต้องการ scan workspace ก่อน
- repo อาจมีหรือไม่มี Flutter project
- ต้องการ bootstrap foundation เพื่อเริ่มใช้ widgets จาก MCP

ต้องทำงานแบบ:
1. ask
2. scan
3. summarize
4. confirm
5. execute

คำถามที่ต้องถามก่อนแตะไฟล์:
- goal: `scan-only`, `bootstrap-existing`, `bootstrap-new`
- workspace state: `existing-flutter`, `no-flutter-yet`, `auto-detect`
- foundation level: `minimal`, `standard`, `full`
- starter widget: `Buttons`, `SearchInput`, `Avatar`, `auto`
- change policy: `additive-only`, `allow-structure-setup`, `ask-before-overwrite`

ทุกข้อที่ถามต้องอธิบายความหมายของตัวเลือกให้ user เข้าใจก่อน

### `flutter-widget-search`

ใช้เมื่อ user รู้ use case แต่ยังไม่รู้ว่าจะใช้ widget ไหน

### `flutter-widget-install`

ใช้เมื่อ user รู้ชื่อ widget แล้วและต้องการดึง source + preview + metadata เข้ามา

### `flutter-widget-adapt`

ใช้เมื่อ widget ถูกติดตั้งแล้วแต่ยังไม่ native กับ repo ปลายทาง

### `flutter-widget-preview`

ใช้เมื่อ widget ยังไม่มี preview ที่รันง่ายใน repo ปลายทาง

### `flutter-widget-figma-to-code`

ใช้เมื่อไม่มี widget เดิมที่ match ดีพอและต้องเริ่มจาก design/spec

### `flutter-widget-audit`

ใช้เมื่ออยาก review integration quality และหาความเสี่ยง

### `flutter-widget-upgrade`

ใช้เมื่ออยาก sync widget ใน repo ปลายทางให้ทัน source-of-truth ล่าสุด

## Guardrails

- ห้าม replace โครงสร้างเดิมของ repo แบบ wholesale
- ห้าม overwrite entrypoint, theme, หรือ localization system แบบไม่ confirm
- ห้ามฮาร์ดโค้ดสีถ้า repo ปลายทางมี token/theme system อยู่แล้ว
- ห้ามข้าม preview/test/docs ถ้า widget เป็น reusable code
