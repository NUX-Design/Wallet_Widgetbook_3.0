# Cursor Flutter Widget Agent Pack

ใช้ไฟล์นี้เป็น fallback instruction pack สำหรับ Cursor เมื่อทำงานกับ `flutter-widget-wallet-mcp`

## Scope

ไฟล์นี้แทน native skill pack แบบชั่วคราว เพราะยังไม่ได้ยืนยันจาก docs ทางการที่เปิดได้ในรอบนี้ว่า Cursor รองรับ `SKILL.md` pack แบบเดียวกับ Claude Code หรือ Kiro

## Required MCP

เชื่อม MCP server `flutter-widget-wallet-mcp` ก่อนใช้งาน workflow ใด ๆ

## Workflow Routing

### `flutter-widget-beginner`

ใช้เมื่อ:
- repo อาจยังไม่มี Flutter project
- ต้องการ scan workspace ก่อน setup
- ต้องการ bootstrap foundation สำหรับเริ่มใช้ widget จาก MCP

บังคับ flow:
1. ask
2. scan
3. summarize
4. confirm
5. execute

ก่อนแก้ไฟล์ ต้องถามอย่างน้อย:
- goal: `scan-only`, `bootstrap-existing`, `bootstrap-new`
- workspace state: `existing-flutter`, `no-flutter-yet`, `auto-detect`
- foundation level: `minimal`, `standard`, `full`
- starter widget: `Buttons`, `SearchInput`, `Avatar`, `auto`
- change policy: `additive-only`, `allow-structure-setup`, `ask-before-overwrite`

อธิบายความหมายของทุกตัวเลือกให้ user ก่อนให้ตอบ

### `flutter-widget-search`

ใช้เมื่อ:
- user รู้ use case แต่ยังไม่รู้ชื่อ widget

ทำงานโดย:
- ใช้ `list_categories`
- ใช้ `search_widgets`
- ใช้ `get_widget_metadata` กับ candidate ที่ดีที่สุด

### `flutter-widget-install`

ใช้เมื่อ:
- user รู้ชื่อ widget ที่ต้องการแล้ว

ทำงานโดย:
- อ่าน `get_widget_metadata` ก่อนเสมอ
- ดึง source ผ่าน `get_widget_code`
- ดึง preview ผ่าน `get_widget_preview`
- adapt ให้เข้ากับ repo ปลายทาง

### `flutter-widget-adapt`

ใช้เมื่อ:
- widget ถูก import มาแล้ว แต่ยังไม่เข้ากับ theme, l10n, structure ของ repo

### `flutter-widget-preview`

ใช้เมื่อ:
- ต้องการ preview entrypoint หรือ Widgetbook/use-case wiring

### `flutter-widget-figma-to-code`

ใช้เมื่อ:
- ไม่มี widget สำเร็จรูปที่ใกล้เคียง
- ต้องแปลงจาก Figma/spec เป็น Flutter widget ใหม่

### `flutter-widget-audit`

ใช้เมื่อ:
- ต้องการ review หลังติดตั้งหรือหลังปรับ widget
- เน้นหาปัญหาเรื่อง theme drift, localization bypass, preview/tests missing

### `flutter-widget-upgrade`

ใช้เมื่อ:
- widget ใน repo ปลายทางอาจ drift จาก source-of-truth ใน MCP

## Guardrails

- ห้าม overwrite ระบบ theme/l10n เดิมแบบเงียบ ๆ
- ห้าม hardcode colors ถ้า repo มี token system อยู่แล้ว
- ห้าม bypass localization สำหรับข้อความที่ควร localize
- ห้ามแก้ generated files ตรง ๆ ถ้ายังมี source-of-truth ที่ควรแก้ก่อน
