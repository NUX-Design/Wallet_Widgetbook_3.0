# คู่มือการดูแลรักษาและอัปเดต Wi Wallet MCP Server 🤖

คู่มือนี้จะอธิบายขั้นตอนการทำงานและวิธีอัปเดตข้อมูลของ MCP Server เมื่อมีการเพิ่ม Widget ใหม่ หรือแก้ไขโค้ดในโปรเจกต์ เพื่อให้ AI Assistant ของคุณได้รับข้อมูลที่ถูกต้องล่าสุดเสมอ

---

## 🏗️ โครงสร้างการทำงาน (Architecture)

ระบบของเรารันด้วยหลักการ **"Hybrid: Schema-driven + Filesystem-driven"** โดยมีขั้นตอนดังนี้:
1.  **Markdown Docs (.md)**: เป็นแหล่งข้อมูลหลัก (Source of Truth) ที่เราเขียนอธิบายวิธีใช้ Widget ต่างๆ
2.  **Schema Generator**: สคริปต์ที่จะไปอ่านไฟล์ Markdown ทั้งหมดแล้วแปลงเป็นไฟล์ `docs/schema.json` เพียงไฟล์เดียว
3.  **Filesystem Indexer**: MCP จะอ่าน `lib/widgets/**`, preview files, และ docs ข้าง widget โดยตรง เพื่อค้นหา widget, metadata, และ source code ล่าสุด
4.  **MCP Server**: ทำหน้าที่ส่งข้อมูลจากทั้ง `schema.json` และ filesystem index ไปให้ AI (เช่น Cursor, Antigravity) ประมวลผล

---

## 🔄 ขั้นตอนการอัปเดตข้อมูล (Workflow)

เมื่อคุณมีการเปลี่ยนแปลงในโปรเจกต์ ให้ทำตามขั้นตอนดังนี้:

### 1. กรณีเพิ่ม Widget ใหม่
1.  สร้างไฟล์ Widget (`.dart`) ตามปกติ
2.  **สำคัญ:** สร้างไฟล์คู่มือ Markdown (เช่น `lib/widgets/my_new_widget_spec.md`) เพื่ออธิบาย:
    *   ชื่อ Widget และหน้าที่
    *   Parameters ต่างๆ ที่รับค่า (Required/Optional)
    *   ตัวอย่างโค้ดการใช้งาน (Code Examples)
3.  เปิด Terminal ที่ Root ของโปรเจกต์แล้วรัน:
    ```bash
    npm run generate-schema
    ```
4.  ถ้ามี preview แยก ให้ตั้งชื่อตาม pattern `preview_{widget}.dart` หรือ `{widget}_preview.dart`
5.  ถ้ามี preview ที่ไม่ใช้ชื่อมาตรฐาน ให้ import widget เป้าหมายตรงๆ และวางไว้ในโฟลเดอร์เดียวกันเมื่อทำได้ เพราะ indexer จะใช้ทั้งชื่อไฟล์, import path, และเนื้อหา preview เพื่อจับคู่

### 2. กรณีแก้ไข Widget เดิม
1.  แก้ไขโค้ดในไฟล์ `.dart`
2.  อัปเดตรายละเอียดในไฟล์ Markdown คู่ของมัน (ไฟล์ `.md` ในโฟลเดอร์เดียวกัน) เพื่อให้ AI รู้ว่ามีอะไรเปลี่ยนไป
3.  รันคำสั่งเดิมเพื่ออัปเดตสมองของ AI:
    ```bash
    npm run generate-schema
    ```

### 3. กรณีเพิ่ม Design Tokens / สีใหม่
1.  แก้ไขข้อมูลในไฟล์ `CODEBASE_CONTEXT.md` (ในส่วนของ Design Tokens)
2.  รันคำสั่ง:
    ```bash
    npm run generate-schema
    ```

### 4. กรณีแก้ installer / client examples / onboarding docs
1.  รัน:
    ```bash
    cd mcp-server
    npm run validate:onboarding
    ```
2.  ถ้าแก้ scripts หรือ contract ที่เกี่ยวข้องด้วย ให้รันเพิ่ม:
    ```bash
    npm run ci:mcp
    ```
3.  ตรวจว่า `mcp.json.example` และไฟล์ใน `mcp-server/examples/` ยังตรงกับ flow ปัจจุบัน

---

## 🛠️ สรุปคำสั่งที่สำคัญ

| คำสั่ง | ผลลัพธ์ |
| :--- | :--- |
| `npm run generate-schema` | อัปเดตไฟล์ `docs/schema.json` ให้เป็นเวอร์ชันล่าสุด |
| `npm run generate-schema:watch` | สั่งให้ระบบคอยจับตาดูไฟล์เอกสาร ถ้ามีการ Save ปุ๊บ มันจะอัปเดต Schema ให้ทันที |
| `cd mcp-server && npm run check:mcp-syntax` | ตรวจ syntax ของไฟล์ JavaScript ทั้งหมดใน MCP server |
| `cd mcp-server && npm test` | รัน MCP unit/integration/snapshot tests |
| `cd mcp-server && npm run verify:mcp` | รัน Inspector verification กับ local stdio MCP server |
| `cd mcp-server && npm run verify:mcp:http` | รัน protocol smoke check กับ hosted Streamable HTTP endpoint แบบ local ชั่วคราว |
| `cd mcp-server && npm run evaluate:mcp` | รัน structured evaluation suite จาก XML |
| `cd mcp-server && npm run validate:onboarding` | ทดสอบ onboarding flow สำหรับ Claude Code, Codex, และ Cursor ด้วย temp config files |
| `cd mcp-server && npm run ci:mcp` | รัน workflow เดียวกับ GitHub Actions สำหรับ MCP |
| `cd mcp-server && npm run start:http` | เปิด hosted Streamable HTTP endpoint สำหรับ zero-clone / remote access |

---

## 🎯 ทำไมต้องทำแบบนี้?

*   **AI ไม่ได้พึ่ง schema อย่างเดียว**: MCP ตัวล่าสุดอ่านทั้ง `schema.json` และ source files จริง เพื่อให้ดึง widget code / preview / metadata ล่าสุดได้
*   **ลดข้อผิดพลาด**: AI จะแนะนำ Parameter ได้ถูกต้อง ไม่มโน (Hallucination) เพราะมีคู่มืออ้างอิงชัดเจน
*   **ทำงานไว**: เมื่อรัน `generate-schema` แล้ว AI จะรับรู้ข้อมูลใหม่ทันทีโดยไม่ต้อง Restart IDE หรือ Restart Server
*   **Metadata มีสัญญาณคุณภาพแล้ว**: `get_widget_metadata` จะมี `metadataSources`, `metadataConfidence`, และ `warnings` เพื่อบอกว่าข้อมูลไหนมาจาก code, docs, หรือ fallback และมี drift ตรงไหนบ้าง
*   **Local parity กับ CI ใช้ command เดียวกัน**: ก่อนเปิด PR ของ MCP ให้รัน `cd mcp-server && npm run ci:mcp` เพื่อจำลอง workflow เดียวกับ `.github/workflows/mcp-ci.yml`
*   **Contract drift จะถูกบล็อกใน test/CI**: ถ้าแก้ tool registry หรือ output contract โดยไม่อัปเดต expected snapshots ใน `mcp-server/tests/snapshots/` ชุด `npm test` จะ fail
*   **Onboarding drift จะถูกจับได้**: ถ้าแก้ installer, examples, หรือ docs แล้วทำให้ flow ของ Claude Code / Codex / Cursor พัง ชุด `npm run validate:onboarding` ควร fail
*   **Remote HTTP เป็น supported transport แล้ว**: ดู contract ของ auth boundary, freshness model, refresh path, และ branch/commit pinning ได้ที่ [REMOTE_MODE_DECISION.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/REMOTE_MODE_DECISION.md)
*   **Version/release/compatibility policy มี source-of-truth แล้ว**: ดู [RELEASE_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/RELEASE_POLICY.md), [CHANGELOG.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/CHANGELOG.md), และ [COMPATIBILITY_POLICY.md](/Users/Niwat.yah/flutter_widgetbook_3.0/mcp-server/COMPATIBILITY_POLICY.md)
*   **Structured logs ใช้ env var เดียว**: ตั้ง `MCP_LOG_LEVEL=debug` เพื่อดู runtime events ของ `server.started`, `tool.call.*`, `widget_catalog.load`, และ `widget_catalog.search`
*   **Hosted endpoint มี freshness surface ชัด**: ใช้ `GET /health` และ `GET /info` เพื่อตรวจ `commitSha`, `deployedAt`, `repoIdentity`, และ `namespace`; ใช้ `POST /admin/refresh` เพื่อ rotate snapshot แบบ atomic

## 🧠 หมายเหตุเชิงสถาปัตยกรรมของ Indexer

- ภายใน `mcp-server/catalog/` ตอนนี้แยก responsibility แล้วเป็น 4 ชั้นหลัก:
  - filesystem discovery
  - Dart parsing
  - markdown/doc enrichment
  - search scoring
- ลำดับ precedence ของ metadata คือ `code > widget-local docs > broader docs/schema`
- `updatedAt` จะพยายามอ่านจาก git history ก่อน และจะ fallback ไปใช้ filesystem mtime ถ้า git ใช้งานไม่ได้
- ตอนนี้ยังใช้แนวทาง regex/filesystem-driven parser ต่อไปก่อน จนกว่าจะมี test coverage ใน Phase 3 มากพอให้เปลี่ยนไป analyzer-backed parsing ได้อย่างปลอดภัย

---

**💡 เคล็ดลับ:** หากต้องการให้ AI เข้าใจโปรเจกต์คุณเก่งๆ ให้เน้นเขียนไฟล์ `.md` ให้ละเอียดและมีตัวอย่างโค้ดที่หลากหลายครับ!
