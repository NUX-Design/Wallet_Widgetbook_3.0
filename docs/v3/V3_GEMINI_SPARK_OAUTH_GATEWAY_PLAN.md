# Widget V3 Gemini Spark OAuth Gateway Plan

สถานะ: Planning — `PLAN_APPROVED`
เวอร์ชัน: `v0.4`
อัปเดตล่าสุดเมื่อ: `2026-08-04`
ขอบเขต: OAuth-compatible auth edge สำหรับ Gemini Spark โดยไม่เปลี่ยน MCP runtime เดิม

## Goal

สร้าง OAuth-compatible MCP Resource Gateway เป็น auth edge ด้านหน้า hosted MCP เดิม เพื่อให้ Gemini Spark เชื่อมต่อ Widget V3 ผ่าน OAuth ได้ โดยคง endpoint เดิม, static bearer tokens, tool contracts, preview delivery และ local `stdio` สำหรับ Codex, Claude และ Cursor ไว้โดยไม่เปลี่ยนแปลง

## Current State

- Hosted MCP เดิม: `https://flutter-widget-wallet-mcp.onrender.com/mcp`
- Transport: Streamable HTTP
- Authentication เดิม: `Authorization: Bearer <token>`
- Local clients ยังสามารถใช้ `stdio` จาก `mcp-server/index.js`
- Hosted endpoint expose เฉพาะ read-only tools; ณ เวลาจัดทำแผนมี 28 tools รวม Widget V3
- Preview bundle พร้อมใช้งานและต้องรักษา freshness invariant เดิม
- Gemini Spark Custom Connected Apps รองรับ remote MCP ผ่าน OAuth แต่ไม่มีช่องกำหนด arbitrary static `Authorization` header

จำนวน tools เป็น baseline ณ เวลาจัดทำแผน ไม่ใช่ค่าที่ควร hardcode ใน Gateway การตรวจ regression ต้องเทียบ tool contracts กับ upstream version ที่ deploy จริง

## Non-Goals

- ไม่สร้าง MCP catalog, tool registry หรือ widget source-of-truth ตัวที่สอง
- ไม่แทนที่ hosted Render MCP เดิม
- ไม่เปลี่ยน config ของ Codex, Claude, Cursor หรือ local `stdio` users
- ไม่ยกเลิกหรือ rotate bearer tokens ของผู้ใช้เดิมในงานนี้
- ไม่เปิดเผย `MCP_REMOTE_PROXY_SHARED_SECRET` ให้ Gateway, Gemini หรือ external clients
- ไม่ hand-roll OAuth Authorization Server
- ไม่เพิ่ม write tools หรือขยาย hosted read-only boundary

## Target Architecture

```text
                         +------------------------------+
                         | Authorization Server         |
                         | managed IdP / mature library |
                         +---------------+--------------+
                                         |
                           OAuth code/token/metadata
                                         |
                                         v
+---------------+      OAuth      +------+------------------+
| Gemini Spark  | --------------> | MCP Resource Gateway    |
| Connected App |                 | auth edge + safe proxy  |
+---------------+                 +------------+-------------+
                                                  |
                                   dedicated upstream bearer
                                                  |
                                                  v
                                 +----------------+----------------+
                                 | Existing Render MCP             |
                                 | /mcp + existing read-only tools |
                                 +---------------------------------+

Codex / Claude / Cursor ----------> Existing Render MCP
Local stdio clients --------------> mcp-server/index.js
```

Gateway เป็น Resource Server และ proxy เท่านั้น ส่วน Authorization Server เป็น component แยกที่ดูแล authorization lifecycle

## Responsibility Boundaries

### Authorization Server

ใช้ managed Identity Provider หรือ mature, actively maintained OAuth Authorization Server library ห้ามเขียน endpoints เหล่านี้เอง

- `/authorize`
- `/token`
- Authorization Code flow
- PKCE โดยอนุญาตเฉพาะ `S256`
- `state` validation
- exact-match redirect URI allowlist
- consent และ client authorization policy
- static client registration หรือ restricted Dynamic Client Registration
- refresh-token lifecycle หาก Gemini Spark ต้องใช้จริง
- `nonce` เฉพาะเมื่อใช้ OIDC หรือ provider กำหนด ไม่ถือเป็นข้อบังคับทั่วไปของ OAuth Authorization Code

### MCP Resource Gateway

- publish OAuth Protected Resource Metadata ตาม RFC 9728
- ตอบ unauthenticated `/mcp` ด้วย `401` และ `WWW-Authenticate` ที่อ้าง `resource_metadata`
- validate bearer token ผ่าน JWT/JWKS หรือ opaque-token introspection ตาม provider
- ตรวจ issuer, expiry, resource/audience, scope, subject และ client identity
- enforce RFC 8707 resource/audience binding
- bind MCP session กับ OAuth identity
- proxy MCP Streamable HTTP ไปยัง upstream แบบตายตัว
- strip sensitive และ hop-by-hop headers
- inject dedicated upstream bearer เท่านั้น
- rate limit, timeout, body limit, audit และ log redaction

### Existing Render MCP

- ยังคงเป็น MCP runtime, catalog และ tool-contract source of truth เพียงตัวเดียว
- ยังคงรับ direct bearer tokens ของผู้ใช้เดิม
- เพิ่ม gateway-only bearer แบบ additive
- ยังคง read-only remote tool boundary และ preview delivery เดิม

## Blocking Decisions

ต้องได้รับอนุมัติก่อนเริ่ม implementation:

1. **Authorization Server / IdP** — เลือก managed provider หรือ mature maintained library
2. **Gateway hosting** — เลือก platform, region, custom domain และงบประมาณต่อเดือน
3. **Identity model** — single owner, allowlisted users หรือ multi-user
4. **Client registration** — static registration หรือ restricted DCR
5. **Scaling model** — single instance ในระยะแรก หรือ multi-instance พร้อม shared session state/session affinity

ห้ามอนุมาน provider-specific behavior จนกว่าจะเลือก provider และทดสอบกับ Gemini Spark จริง

## Phase 1 — Discovery And Architecture Approval

### Deliverables

- บันทึก redirect URI ที่ Gemini Spark แสดงจริง
- ทำ staging handshake spike เพื่อตรวจลำดับ:
  - Protected Resource Metadata discovery
  - `401 WWW-Authenticate`
  - Authorization Server discovery
  - client registration
  - authorization/token exchange
  - MCP `initialize`
- เลือก Authorization Server, hosting, identity model, registration policy และ scaling model
- สร้าง Architecture Decision Record
- สร้าง data-flow diagram และ threat model
- สร้าง secret ownership matrix
- ระบุ OAuth/MCP protocol versions ที่ทดสอบจริง

### Acceptance Gate

- ผู้ใช้อนุมัติ blocking decisions ทั้งหมด
- ขอบเขต Authorization Server, Resource Gateway และ existing MCP แยกกันชัดเจน
- ไม่มี production secret ถูกใช้ใน spike
- ยืนยันได้ว่า Gateway เป็น additive auth edge ไม่ใช่ MCP service ตัวที่สอง

## Phase 2 — Provision Gateway-Only Upstream Credential

### Deliverables

- สร้าง `GATEWAY_UPSTREAM_BEARER` ใหม่
- เพิ่ม token ใหม่เข้า `MCP_REMOTE_BEARER_TOKENS` แบบ add-only
- เก็บ user bearer tokens เดิมทุกตัวไว้
- ตรวจ overlap window ที่ token เดิมและ gateway token ใช้งานพร้อมกันได้
- จัดทำ rotation runbook:
  1. add new gateway token
  2. verify upstream access
  3. switch Gateway
  4. observe traffic
  5. remove old gateway-only token
- จัดทำ emergency revoke procedure สำหรับ gateway token โดยไม่แตะ user tokens

### Acceptance Gate

- direct bearer เดิมยังผ่าน remote verification
- gateway bearer เรียก upstream read-only contracts ได้ครบตาม deployed version
- Gateway ไม่ได้รับและไม่รู้จัก `MCP_REMOTE_PROXY_SHARED_SECRET`
- ไม่มี token literal อยู่ใน Git, docs, logs หรือ PR text

## Phase 3 — Implement Authorization Configuration And Resource Gateway

### Authorization Configuration

- Authorization Code + PKCE S256
- exact-match redirect URI allowlist
- `state` validation
- consent และ identity policy ตามที่อนุมัติ
- refresh token เฉพาะเมื่อ staging handshake ยืนยันว่าจำเป็น
- static client registration เป็น default ที่ง่ายที่สุด
- restricted DCR ใช้เฉพาะเมื่อ Gemini Spark ต้องการจริง
- `nonce` ใช้เฉพาะ OIDC/provider-mandated flow

### OAuth Resource Contract

- publish `/.well-known/oauth-protected-resource`
- ชี้ไปยัง Authorization Server ที่เลือก
- unauthenticated `/mcp` ตอบ `401`
- `WWW-Authenticate: Bearer` ต้องมี `resource_metadata`
- validate token claims หรือ introspection result:
  - issuer
  - expiration
  - resource/audience
  - scope เช่น `mcp:read`
  - subject
  - client identity
- รองรับ JWT ผ่าน JWKS หรือ opaque token ผ่าน introspection ตาม provider

### Safe Proxy Contract

- ตรึง upstream origin และ `/mcp` path ใน server-side configuration
- client เปลี่ยน upstream destination ไม่ได้
- ปฏิเสธเฉพาะ routing controls ที่ Gateway นิยามเองใน URL/query/reserved headers
- ห้าม block, inspect หรือ rewrite valid JSON-RPC tool arguments จากชื่อ field เช่น `repo`, `branch`, `commit` หรือ `target`
- หลังตรวจ request-size limit และ JSON-RPC shape ให้ส่ง body เดิมต่อไปโดยไม่เปลี่ยน semantics
- strip request headers:
  - client `Authorization`
  - cookies
  - proxy/internal secrets
  - hop-by-hop headers
- inject เฉพาะ `Authorization: Bearer <GATEWAY_UPSTREAM_BEARER>` ไป upstream
- strip sensitive และ hop-by-hop response headers ก่อนส่งกลับ client
- preserve MCP-required headers และ behavior:
  - `Accept`
  - `Content-Type`
  - `MCP-Protocol-Version`
  - `MCP-Session-Id`
  - `Last-Event-ID`
  - streaming และ backpressure
  - cancellation
  - SSE reconnect

### Session Security

- bind `MCP-Session-Id` กับ tuple `(issuer, subject, client_id)`
- ปฏิเสธ session reuse ข้าม identity
- ระยะแรกใช้ single instance ได้หากระบุ scaling constraint ชัดเจน
- ก่อน scale หลาย instance ต้องใช้ shared session mapping หรือ proven session affinity

### Security Controls

- TLS-only
- per-subject/client/IP rate limits
- global rate limit
- request body-size limit
- upstream connection และ response timeouts
- CORS deny-by-default เว้นแต่มี browser requirement ที่ยืนยันแล้ว
- log redaction สำหรับ tokens, codes, cookies, secrets และ sensitive body content
- structured audit events โดยไม่บันทึก source code หรือ credentials
- read-only capability boundary ต้องตรงกับ upstream

### Acceptance Gate

- automated tests ใน Phase 5 ผ่านบน staging
- Gateway ไม่เพิ่ม, ลบ หรือเปลี่ยน tool contracts
- request/response headers และ sessions ไม่รั่วข้าม identity

## Phase 4 — Staging Deployment And Real Gemini Handshake

### Deliverables

- deploy Gateway บน staging URL แยกจาก production MCP URL เดิม
- ตั้ง staging OAuth client และ allowlist เฉพาะผู้ทดสอบ
- generic MCP client smoke test:
  - discovery
  - authorization
  - `initialize`
  - `tools/list`
  - representative read-only `tools/call`
- เชื่อม Gemini Spark จริงกับ staging
- บันทึกและ archive handshake evidence:
  - metadata fetches
  - `401` challenge behavior
  - authorization request
  - token exchange outcome โดย redact secrets
  - first MCP session
  - session/reconnect behavior
- แก้ Gemini-specific deviations ก่อนผ่าน phase

### Acceptance Gate

- Gemini Spark จริงเชื่อม staging สำเร็จ
- evidence ไม่มี token, client secret หรือ authorization code
- production canary จะไม่ใช่การเชื่อม Gemini ครั้งแรก
- staging failures ไม่กระทบ existing Render MCP users

## Phase 5 — Validation And Regression Gates

### OAuth Negative Tests

- missing token
- expired/revoked token
- wrong issuer
- wrong resource/audience
- insufficient scope
- invalid client identity
- redirect URI mismatch
- `state` mismatch
- PKCE downgrade หรือ verifier mismatch
- invalid JWKS signature หรือ failed introspection
- restricted DCR policy violation หากเปิด DCR

### MCP Protocol Tests

- `initialize`
- `tools/list`
- representative `tools/call`
- JSON-RPC errors
- SSE streaming
- cancellation
- reconnect ด้วย `Last-Event-ID`
- session continuity
- cross-identity session reuse ต้อง fail
- upstream timeout/disconnect behavior

### Header And Secret Hygiene Tests

- client authorization/cookies ไม่ไปถึง upstream
- upstream bearer ไม่กลับไปหา client
- proxy/internal headers ไม่รั่วสองทิศทาง
- hop-by-hop headers ถูกกรอง
- logs ไม่บันทึก credentials หรือ sensitive body

### Legacy Regression Gates

- existing direct bearer endpoint ผ่าน `verify:mcp:remote:v3`
- local `stdio` MCP test suite ผ่าน
- tool names, schemas และ contracts ตรงกับ upstream deployed version
- remote read-only boundary ไม่เปลี่ยน
- preview bundle ยัง `available` และ `fresh`
- existing Codex, Claude และ Cursor configs ไม่ต้องแก้

### Acceptance Gate

- ทุก security, protocol และ regression gate ผ่านบน staging
- ไม่มี unresolved high-severity finding
- rollback rehearsal สำเร็จ

## Phase 6 — Production Canary, Rollout And Rollback

### Production Rollout

1. สร้าง production OAuth client
2. ลงทะเบียน exact redirect URI
3. deploy production Gateway URL ใหม่โดยไม่ทับ endpoint เดิม
4. ใช้ production gateway-only bearer
5. เปิดให้ Gemini Spark account แบบ allowlist จำนวนเล็กน้อย
6. ทดสอบ discovery, authorization, MCP initialize, tool calls และ streaming
7. monitor อย่างน้อย 24–72 ชั่วโมงก่อนขยายผู้ใช้
8. เพิ่ม Gemini onboarding docs แบบ additive โดยไม่แทนที่คู่มือ client เดิม

### Monitoring

- authorization success/failure rate
- JWKS/introspection failures
- gateway `401`/`403`
- upstream `401`/`5xx`
- latency และ timeouts
- stream disconnect/reconnect
- session identity mismatch
- rate-limit events
- secret-redaction failures

### Rollback

1. ปิดหรือ revoke Gemini OAuth client
2. disable Gateway routing หรือ production gateway URL
3. รอ active MCP sessions drain
4. revoke เฉพาะ gateway-only upstream bearer
5. ยืนยัน existing Render endpoint และ user bearer tokens ยังทำงาน
6. เก็บ incident evidence ที่ redact แล้วสำหรับแก้ไขก่อน rollout รอบใหม่

### Acceptance Gate

- Gemini canary ใช้งานจริงได้ตลอด observation window
- legacy regression gates ยังผ่าน
- monitoring ไม่มี secret leakage หรือ session isolation failure
- rollback สามารถปิด Gateway โดยไม่หยุด existing MCP users

## Definition Of Done

- [ ] Blocking decisions ได้รับอนุมัติและบันทึกใน ADR
- [ ] Authorization Server และ Resource Gateway แยก responsibility ชัดเจน
- [ ] ไม่มี hand-rolled Authorization Server endpoints
- [ ] Gemini Spark ผ่าน staging discovery, OAuth และ MCP handshake จริง
- [ ] staging handshake evidence ถูก archive โดยไม่มี secret
- [ ] Production Gemini canary ผ่าน OAuth, `initialize`, `tools/list`, representative Widget V3 reads, streaming, cancellation และ reconnect
- [ ] RFC 9728 metadata, `WWW-Authenticate` และ RFC 8707 resource binding ผ่าน validation
- [ ] JWT/JWKS หรือ opaque introspection ทำงานตาม provider ที่เลือก
- [ ] PKCE S256, `state`, exact redirect allowlist และ registration policy ผ่าน security tests
- [ ] MCP session ถูก bind กับ OAuth identity และป้องกัน cross-user reuse
- [ ] Header filtering, rate limits, body limits, timeouts และ log redaction ผ่าน tests
- [ ] Gateway ไม่ได้รับ `MCP_REMOTE_PROXY_SHARED_SECRET`
- [ ] Gateway inject เฉพาะ gateway-only upstream bearer
- [ ] Existing direct bearer clients และ local `stdio` users ผ่าน regression โดยไม่แก้ config
- [ ] Upstream tool contracts, read-only boundary และ preview freshness ไม่เปลี่ยนจาก deployed version
- [ ] Gateway credential rotation runbook ผ่าน rehearsal
- [ ] Monitoring, incident response และ rollback runbooks พร้อมใช้
- [ ] Rollback Gateway ได้โดย existing Render MCP ยังคงให้บริการ

## Highest Risks And Mitigations

### 1. Gemini Spark OAuth/MCP Interoperability

**Risk:** Gemini Spark อาจมี discovery, client registration หรือ Streamable HTTP behavior ที่ต่างจากสมมติฐาน

**Mitigation:** ทดสอบและ archive handshake กับ Gemini Spark จริงบน staging ใน Phase 4 ห้ามให้ production canary เป็นการเชื่อม Gemini ครั้งแรก

### 2. Stream And Session Proxy Fidelity

**Risk:** Gateway อาจทำให้ SSE, backpressure, cancellation, reconnect หรือ `MCP-Session-Id` ผิด semantics

**Mitigation:** protocol integration tests ครบทั้ง lifecycle, single-instance deployment ระยะแรก และ identity-bound session mapping

### 3. Credential Or Header Leakage

**Risk:** client token, upstream bearer หรือ internal headers รั่วผ่าน forwarding, errors หรือ logs

**Mitigation:** explicit allowlist/denylist ของ headers, bidirectional hygiene tests, structured log redaction, secret scan และ gateway-only credential rotation

### 4. Regression For Existing Users

**Risk:** การเปลี่ยน upstream token config หรือ deployment ทำให้ direct bearer/local `stdio` users ใช้งานไม่ได้

**Mitigation:** add-only token provisioning, overlap window, legacy regression gates ทุก phase และ Gateway URL แบบ additive ที่ rollback แยกได้

## Approval Record

- Planner: `claude-fable-5`
- Planner result: `PLAN_REVISION v0.4`
- Advisor result: `PLAN_APPROVED`
- Findings incorporated: `ADV-001` ถึง `ADV-007`

เอกสารนี้เป็นแผนเท่านั้น การเลือก provider, สร้าง infrastructure, เพิ่ม secrets, deploy หรือเปลี่ยน production environment ต้องได้รับอนุมัติแยกก่อนลงมือ
