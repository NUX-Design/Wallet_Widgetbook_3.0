<img width="1920" height="1080" alt="Cover" src="https://github.com/user-attachments/assets/4e0d1102-da06-4f92-bbfc-20123db01353" />

# Flutter Widgetbook Library

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Flutter UI Library สำหรับ Dart/Flutter ที่โฟกัสงานแนว Finance, Wallet, และ Banking โดย repo นี้เป็นแหล่งรวม reusable widgets, Design System, Design Tokens, i18n, Themes, Foundation layers และ preview workflows ที่แปลงต่อมาจาก Figma design components เพื่อให้ทีมพัฒนาใช้งานซ้ำได้จริงในระดับ production

นอกจากฝั่ง UI แล้ว repo นี้ยังมี `mcp-server/` สำหรับเชื่อมต่อ AI agents ผ่าน Model Context Protocol (MCP) และมีเอกสารบริบทสำหรับ agent เช่น `AGENTS.md` และ `MEMORY.md` เพื่อให้ agent เข้าใจกฎของ repo, อ่าน source-of-truth ถูกจุด, และดึง widget/code metadata ไปใช้ได้อย่างเป็นระบบ

## Table of Contents

- [Repo นี้คืออะไร](#repo-นี้คืออะไร)
- [สิ่งที่มีใน repo](#สิ่งที่มีใน-repo)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Design System Foundation](#design-system-foundation)
- [MCP Server และ Agent Skills](#mcp-server-และ-agent-skills)
- [Setup MCP สำหรับ Codex, Claude Code, Kiro](#setup-mcp-สำหรับ-codex-claude-code-kiro)
- [ทำไมการใช้ MCP + Skills ของ repo นี้จึงมีประโยชน์](#ทำไมการใช้-mcp--skills-ของ-repo-นี้จึงมีประโยชน์)
- [Useful Commands](#useful-commands)

## Repo นี้คืออะไร

repo นี้ทำหน้าที่เป็น source-of-truth ของ Flutter widget library สำหรับงานสายการเงิน โดยเน้น 3 เรื่องพร้อมกัน:

1. UI Components ที่พร้อม reuse
2. Design System และ theme/token foundations ที่สม่ำเสมอ
3. Agent tooling สำหรับให้ AI assistants อ่าน ค้นหา และนำ component ไปใช้ต่อได้แม่นขึ้น

ภาพรวมของสิ่งที่ repo นี้ครอบคลุม:

- Flutter reusable widgets สำหรับ Finance / Wallet / Banking flows
- Widgetbook catalog และ standalone previews สำหรับ inspect UI แยกชิ้น
- Theme system ที่รองรับ light/dark
- Design tokens ที่ดึงไปใช้ต่อได้แบบเป็นระบบ
- Localization source + generator pipeline
- Widget docs / metadata / previews ที่เกาะกับ source code จริง
- MCP server สำหรับ AI agents ที่ต้องการค้นหา widget, อ่าน metadata, และดึงตัวอย่างโค้ด

## สิ่งที่มีใน repo

- `lib/widgets/` รวม reusable widgets หลัก เช่น button, card, drawer, receipt, input, avatar, tab, navigator bar, snack bar, loading, shortcut menu และอื่นๆ
- `lib/config/themes/` เป็นศูนย์กลางของ theme primitives และ color tokens
- `lib/l10n/localization.json` เป็น editable source of truth สำหรับข้อความหลายภาษา
- `lib/widgetbook.dart` และ `lib/widgetbook_use_cases.dart` รองรับการ preview component ผ่าน Widgetbook
- `mcp-server/` เป็น MCP server สำหรับให้ agent/tool ภายนอก query ข้อมูล widget และ design-system ได้
- `AGENTS.md` และ `MEMORY.md` เป็น repo-specific agent context ที่ช่วยให้ agent ทำงานกับ repo นี้ได้ตรงกฎและตรงโครงสร้างจริง

## Project Structure

```text
lib/
├── config/themes/            # Theme system, tokens, base theme
├── generated/intl/           # Generated localization output
├── l10n/                     # Localization source + ARB files
├── providers/                # ThemeProvider / LocaleProvider
├── widgets/                  # Reusable UI components
├── main.dart                 # Demo app entry
├── widgetbook.dart           # Widgetbook entry
└── widgetbook_use_cases.dart # Manual Widgetbook use cases

mcp-server/                   # MCP server for AI agents
scripts/                      # Schema / docs tooling
test/                         # Flutter tests
task/                         # Backlog / execution tracking
```

## Quick Start

### Prerequisites

- Flutter SDK `^3.7.2`
- Dart SDK
- Node.js `18+` สำหรับ MCP tooling และ docs/schema scripts

### Run the Flutter project

```bash
flutter pub get
dart run tool/generate_arb.dart
flutter gen-l10n
flutter run
```

### Run Widgetbook

```bash
flutter run -t lib/widgetbook.dart -d chrome
```

### Run MCP server locally

```bash
cd mcp-server
npm install
npm start
```

## Design System Foundation

repo นี้ไม่ได้เก็บแค่ widget ปลายทาง แต่เก็บ foundation ที่พร้อมนำไปใช้ต่อได้ทั้งระบบ:

- `Design Tokens`
  ใช้ token-based color access ผ่าน theme layer แทนการ hardcode สีใน shared widgets
- `Themes`
  รองรับ light/dark mode และใช้ theme primitives ร่วมกันทั้ง library
- `i18n`
  มี editable source (`lib/l10n/localization.json`) และ generation pipeline ไปสู่ ARB/intl outputs
- `Widgetbook + Standalone Preview`
  ใช้ preview ได้ทั้งแบบ catalog และแบบ run แยกไฟล์สำหรับ debug component
- `Foundation for Financial UI`
  widget และ naming หลายส่วนถูกออกแบบมาสำหรับ use cases แนว wallet, payment, account summary, receipt, transaction, drawer actions และ navigation patterns

รองรับภาษาหลักในระบบปัจจุบัน:

- English (`en`)
- Thai (`th`)
- Chinese (`zh`)
- Russian (`ru`)
- Myanmar (`my`)

## MCP Server และ Agent Skills

### MCP Server คืออะไร

MCP หรือ Model Context Protocol คือมาตรฐานสำหรับเปิดให้ AI agents เรียกใช้ tools ภายนอกได้แบบเป็นโครงสร้างเดียวกัน เช่น ค้นหา widget, อ่าน metadata, ดึง source code หรืออ่าน design-system rules จาก repo นี้โดยตรง

ใน repo นี้ MCP server อยู่ที่ `mcp-server/` และรองรับทั้ง:

- `local stdio`
  เหมาะกับคนที่ clone repo ลงเครื่องและอยากให้ agent อ่าน source ล่าสุดจาก working tree จริง
- `hosted streamable-http`
  เหมาะกับ zero-clone / remote access โดยให้ client เชื่อมผ่าน URL แทน local path

### Agent Skills ในบริบทของ repo นี้คืออะไร

ในทางปฏิบัติ repo นี้มี 2 ชั้นที่ช่วย agent ทำงานได้ดีขึ้น:

1. `AGENTS.md` และ `MEMORY.md`
   เป็น repo-specific operating rules / memory ที่บอกลำดับการอ่านไฟล์, source-of-truth, คำสั่งที่ใช้จริง, และข้อควรระวังของโปรเจกต์
2. `MCP tools`
   เป็น machine-callable tools ที่ agent ใช้ query ข้อมูลจาก repo ได้โดยไม่ต้องเดาโครงสร้างเอง

แนวคิดนี้ทำให้หลาย agent เช่น Codex, Claude Code, Cursor, Antigravity หรือ Kiro สามารถทำงานบนฐานความเข้าใจเดียวกันได้ง่ายขึ้น แม้ระดับการรองรับจริงของแต่ละ client จะไม่เท่ากัน

### MCP server ช่วยอะไรได้บ้าง

tools หลักที่ repo นี้เปิดให้ agent ใช้งาน เช่น:

- `list_categories`
- `list_widgets`
- `search_widgets`
- `get_widget_details`
- `get_widget_metadata`
- `get_widget_code`
- `get_widget_preview`
- `get_design_system_info`
- `get_color_token`
- `get_codebase_patterns`
- `generate_widget_code`

ผลคือ agent สามารถ:

- ค้นหา widget ที่มีอยู่ก่อนสร้างใหม่ซ้ำ
- อ่าน preview/doc/widget metadata ได้ตรงจาก repo
- ดึงโค้ด component ไป reuse หรืออ้างอิงต่อได้
- เข้าใจกฎ design-system และ codebase patterns ก่อน generate code
- ใช้ข้อมูลจาก design system นี้ไปสร้าง component ใหม่ใน project ปลายทางได้แม่นขึ้น

ถ้าใช้งานผ่าน `hosted streamable-http` endpoint agent ไม่จำเป็นต้อง clone repo นี้ลงเครื่องก่อนก็ยังสามารถ:

- ค้นหา widget ที่ใกล้เคียงกับสิ่งที่ต้องการ
- อ่าน metadata, props, preview และแนวทาง implementation
- ดึง source code ของ widget ที่มีอยู่
- ใช้ pattern/token/theme rules เดิมไป generate component สำหรับ project ของตัวเองได้เลย

สรุปคือ repo นี้สามารถทำหน้าที่เป็น `remote source of truth` สำหรับ UI library ได้ โดย external project หรือ AI agent เชื่อมผ่าน MCP แล้วนำ component widgets เข้าไปสร้างหรือปรับใช้ต่อใน project ปลายทางได้ทันที แม้ไม่ได้ clone repo นี้ไว้ในเครื่อง

## Setup MCP สำหรับ Codex, Claude Code, Kiro

หัวข้อนี้แสดงเฉพาะการ config แบบ `remote` เท่านั้น โดยสมมติว่าคุณมี hosted MCP endpoint อยู่แล้ว เช่น:

- `https://flutter-widget-wallet-mcp.onrender.com/mcp`
- และมี access token สำหรับ reverse proxy / gateway ของ endpoint นั้น

config อ้างอิงหลักของ repo อยู่ที่ `mcp-server/examples/remote.generic.mcp.json`

### 1. Codex

ใช้ remote MCP URL พร้อม `Authorization` header:

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp-remote": {
      "url": "https://flutter-widget-wallet-mcp.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer <EDGE_ACCESS_TOKEN>"
      }
    }
  }
}
```

### 2. Claude Code

ใช้ remote MCP URL shape เดียวกัน:

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp-remote": {
      "url": "https://flutter-widget-wallet-mcp.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer <EDGE_ACCESS_TOKEN>"
      }
    }
  }
}
```

### 3. Kiro

ถ้า Kiro เวอร์ชันที่ใช้อยู่รองรับ remote MCP แบบ `url` + `headers` ก็ใช้ generic shape เดียวกันได้:

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp-remote": {
      "url": "https://flutter-widget-wallet-mcp.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer <EDGE_ACCESS_TOKEN>"
      }
    }
  }
}
```

หมายเหตุ:

- remote example ของ repo คือ `mcp-server/examples/remote.generic.mcp.json`
- ฝั่ง protocol ของ remote `streamable-http` รองรับจริงใน repo นี้
- แต่ remote integration แบบ host-app โดยตรงสำหรับ `Claude Code` และ `Codex` ยังเป็น `best-effort / unverified` ตาม `mcp-server/COMPATIBILITY_POLICY.md`
- `Kiro` ไม่มี template ที่ repo generate ให้โดยตรง จึงควรมองเป็น generic remote example เช่นกัน
- ถ้าต้องการตรวจ endpoint ที่ deploy จริง ให้ใช้ `cd mcp-server && npm run verify:mcp:remote`

## ทำไมการใช้ MCP + Skills ของ repo นี้จึงมีประโยชน์

### 1. ลดการเดาโครงสร้าง repo

agent ไม่ต้องเดาเองว่า widget อยู่ไหน ใช้ theme ยังไง หรือ localization source อยู่ไฟล์ไหน เพราะมีทั้ง repo rules และ machine-callable tools บอกไว้อยู่แล้ว

### 2. ลดการสร้าง component ซ้ำ

แทนที่จะ generate widget ใหม่ทุกครั้ง agent สามารถ `search_widgets` และ `get_widget_metadata` ก่อน เพื่อดูว่ามีของเดิมที่ reuse ได้หรือไม่

### 3. ดึงโค้ดจริงจาก source-of-truth ได้

agent สามารถดึงตัวอย่างโค้ด, preview, metadata และ design-system patterns จาก repo จริง ไม่ต้องอาศัยคำอธิบายกว้างๆ อย่างเดียว

### 4. ไม่ต้อง clone repo ก็ยังสร้าง widget เข้า project ปลายทางได้

ถ้า MCP endpoint ถูก host ไว้แล้ว agent สามารถเชื่อมผ่าน remote URL, อ่าน widget catalog, ดึงโค้ด/metadata, แล้วสร้างหรือปรับ component ลงใน project ปลายทางได้เลย โดยไม่ต้อง clone repo design-system นี้มาก่อน

### 5. ทำงานข้ามหลาย agent ได้สม่ำเสมอขึ้น

เมื่อ repo เดียวกันมีทั้ง MCP tools และ agent context docs การย้ายงานระหว่าง Codex, Claude Code, Cursor หรือ client อื่นจะมีโอกาส drift น้อยลง

### 6. เหมาะกับ workflow จาก Figma ไปสู่ Flutter

เพราะ repo นี้วางตัวเป็นแหล่งรวม design components ที่ถูกแปลงสู่ Flutter widgets พร้อม foundations ทำให้ agent ใช้เป็นฐานสำหรับ generate/compare/refactor งานจาก design specs ได้ดี

## Useful Commands

### Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter run -t lib/widgetbook.dart -d chrome
```

### Localization

```bash
dart run tool/generate_arb.dart
flutter gen-l10n
```

### Widgetbook / Generated files

```bash
dart run build_runner build --delete-conflicting-outputs
```

### MCP Server

```bash
cd mcp-server
npm install
npm start
npm run start:http
npm run verify:mcp
npm run verify:mcp:http
npm run verify:mcp:remote
npm run validate:onboarding
```

## Notes

- ถ้าข้อมูลใน overview docs ไม่ตรงกับ source code ให้เชื่อ `AGENTS.md`, `MEMORY.md`, และ live source files ก่อน
- generated files เช่น localization outputs, Widgetbook generated directories, และ `docs/schema.json` ไม่ควรแก้ด้วยมือ
- ถ้าจะใช้ AI agent กับ repo นี้แบบจริงจัง แนะนำให้อ่าน `AGENTS.md` และ `MEMORY.md` ก่อนทุกครั้ง
