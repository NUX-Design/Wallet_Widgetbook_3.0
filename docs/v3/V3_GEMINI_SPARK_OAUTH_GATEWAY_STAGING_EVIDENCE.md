# Gemini Spark OAuth Gateway — Staging Evidence

วันที่ทดสอบ: `2026-08-05` (Asia/Bangkok)

เอกสารนี้เก็บหลักฐานแบบ redact สำหรับ staging handshake ของ OAuth Resource Gateway โดยไม่บันทึก access token, authorization code, client secret, upstream bearer หรือ Auth0 subject

## Deployment

- Gateway URL: `https://flutter-widget-wallet-oauth-gateway.onrender.com/mcp`
- Existing MCP URL (ไม่เปลี่ยน): `https://flutter-widget-wallet-mcp.onrender.com/mcp`
- Render staging service: `srv-d9p1pf7qj5pc738io7v0`
- Gateway commit ที่ผ่าน Gemini handshake ครั้งแรก: `f57982caf65a598aa8bef0bfe71a8023ec928e96`
- Auth0 tenant region: Japan
- Auth0 flow: Authorization Code, static confidential client, exact Gemini redirect URI, RS256 JWT, audience-bound `mcp:read`
- Identity policy: allowlist เฉพาะ owner subject และ Gemini client

## Real Gemini Spark Handshake

ลำดับที่ยืนยันจาก Gemini UI, Auth0 logs และ Render logs:

1. Gemini อ่าน Protected Resource Metadata และได้รับ unauthenticated `401` challenge จาก `/mcp`
2. Google account linking ส่งผู้ใช้เข้า Auth0 authorization flow
3. Auth0 บันทึก `Success Login` และ `Success Exchange — Authorization Code for Access Token`
4. Gateway ยอมรับ JWT หลังตรวจ issuer, audience, expiry, scope, subject และ client allowlists
5. Gemini แสดง custom app พร้อมเครื่องมือ `28` รายการ และบันทึก connection สำเร็จ
6. Gemini เรียกเครื่องมือจริงสำเร็จ:
   - `search_v3_widgets`
   - `list_v3_widgets`
   - `list_v3_categories`
7. Gateway บันทึก authenticated POST responses เป็น `200`/`202` โดยใช้ identity hash เท่านั้น

ผลตัวอย่างจาก `search_v3_widgets` แสดง Widget V3 ในหมวด `button` และ `icon_button` โดยไม่เปลี่ยน tool contract ของ upstream

## Deviations Found And Fixed

- Gemini redirect URI ผูกกับ hostname ของ Gateway จึงต่างจาก redirect URI ที่เคยคัดลอกจาก endpoint MCP เดิม ต้องใช้ exact callback ที่ Gemini แสดงสำหรับ Gateway URL
- Auth0 third-party application ต้องเปิด social connection ในระดับ domain ก่อนจึง login ได้
- Render staging เคยเก็บ `GATEWAY_ALLOWED_SUBJECTS` เป็น placeholder ทำให้ JWT ที่ถูกต้องถูกปฏิเสธด้วย `invalid_subject`; แก้ allowlist และ deploy ใหม่แล้ว
- Existing MCP ส่ง InitializeResult ผ่าน SSE ได้ Gateway เดิมตรวจเฉพาะ JSON body จึงสร้าง audit event `gateway.initialize_rejected` แบบ false negative แม้ Gemini ใช้ tools ได้ โค้ดและ regression test ถูกเพิ่มให้ตรวจ JSON-RPC ใน SSE `data` event แบบ fail-closed

## Security Notes

- ไม่มี secret/token/code literal ในเอกสารนี้
- Google social connection ใช้ Auth0 development keys สำหรับ staging เท่านั้น ห้ามใช้เป็น production credential
- Existing bearer clients และ local stdio clients ไม่ถูกแก้ config
- Owner decision `2026-08-05` ปิดรอบนี้เป็น Personal/Staging บน Render Free โดย defer production Google OAuth keys, canary, observation window และ destructive rollback rehearsal; หลักฐานนี้ไม่ใช่ production evidence
