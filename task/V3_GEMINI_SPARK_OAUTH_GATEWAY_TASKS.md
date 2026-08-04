# Widget V3 Gemini Spark OAuth Gateway Tasks

สร้างเมื่อ: `2026-08-04 23:18:05 +0700`
อัปเดตล่าสุดเมื่อ: `2026-08-05 01:12:00 +0700`

Execution checklist นี้แตกจาก [`docs/v3/V3_GEMINI_SPARK_OAUTH_GATEWAY_PLAN.md`](../docs/v3/V3_GEMINI_SPARK_OAUTH_GATEWAY_PLAN.md) (สถานะแผน: `PLAN_APPROVED`, v0.4) งานนี้เป็นการเพิ่ม auth edge (OAuth-compatible MCP Resource Gateway) หน้า hosted MCP เดิม (`https://flutter-widget-wallet-mcp.onrender.com/mcp`) โดยไม่แทนที่หรือแก้ runtime/tool-contract เดิม

> สถานะ execution ปัจจุบัน: local Gateway, Render staging, Auth0 API/Application/permission และ real Gemini Spark staging handshake ผ่านแล้ว; production OAuth credentials/canary, observation window และ rollback rehearsal ยังไม่เสร็จ

## Global Guardrails

- [x] ไม่สร้าง MCP catalog, tool registry หรือ widget source-of-truth ตัวที่สอง
- [x] ไม่แทนที่หรือ downtime hosted Render MCP เดิม
- [x] ไม่แก้ config ของ Codex, Claude, Cursor หรือ local `stdio` users
- [x] ไม่ยกเลิกหรือ rotate bearer tokens ของผู้ใช้เดิมในงานนี้
- [x] Gateway ไม่ได้รับและไม่รู้จัก `MCP_REMOTE_PROXY_SHARED_SECRET`
- [x] ไม่ hand-roll OAuth Authorization Server เอง (ต้องใช้ managed IdP หรือ mature maintained library)
- [x] ไม่เพิ่ม write tools หรือขยาย hosted read-only boundary
- [x] ไม่ hardcode จำนวน tools ปัจจุบัน (28) ในโค้ด Gateway — regression ต้องเทียบกับ upstream deployed version เสมอ

## Exit Criteria

- [ ] Gemini Spark เชื่อมต่อผ่าน OAuth ได้จริงบน production ผ่าน allowlisted canary
- [ ] existing direct bearer clients (Codex/Claude/Cursor/local stdio) ผ่าน regression โดยไม่แก้ config
- [ ] upstream tool contracts, read-only boundary และ preview freshness ไม่เปลี่ยนจาก deployed version
- [ ] rollback ปิด Gateway ได้โดย existing Render MCP ยังให้บริการต่อเนื่อง
- [ ] ไม่มี secret/token literal รั่วใน Git, docs, logs หรือ PR text ตลอดทุก phase

## Blocking Decisions (ต้องอนุมัติก่อนเริ่ม Phase 1 implementation)

- [x] **Authorization Server / IdP** — Auth0
- [x] **Gateway hosting** — Render Singapore, Render URL, Free staging `$0/month`; paid production plan deferred จนก่อน canary
- [x] **Identity model** — single owner พร้อม subject/client allowlists
- [x] **Client registration** — static registration; restricted DCR deferred
- [x] **Scaling model** — single instance ระยะแรก

ห้ามอนุมาน provider-specific behavior จนกว่าจะเลือก provider และทดสอบกับ Gemini Spark จริง

## Phase 1 — Discovery And Architecture Approval

### GW-01: Record Gemini Spark redirect URI and run staging handshake spike

- [x] บันทึก redirect URI ที่ Gemini Spark Custom Connected Apps แสดงจริง
- [x] ทำ staging handshake spike ตรวจลำดับ: Protected Resource Metadata discovery → `401 WWW-Authenticate` → Authorization Server discovery → client registration → authorization/token exchange → MCP `initialize`
- [x] ระบุ OAuth/MCP protocol baseline สำหรับ staging spike
- [x] ยืนยันว่า local spike/tests ไม่ใช้ production secret

Depends on: Blocking Decisions (Authorization Server / IdP)

Evidence: redirect URI และ protocol baseline ใน `docs/v3/adr/ADR-001-GEMINI-SPARK-OAUTH-GATEWAY.md`; real staging sequence ใน `docs/v3/V3_GEMINI_SPARK_OAUTH_GATEWAY_STAGING_EVIDENCE.md`; local tests ใช้ keys/identity จำลองเท่านั้น

### GW-02: Select architecture parameters and record ADR

- [x] เลือก Authorization Server, hosting, identity model, registration policy และ scaling model ตาม Blocking Decisions
- [x] สร้าง Architecture Decision Record (ADR)
- [x] ยืนยันขอบเขต Authorization Server / Resource Gateway / existing MCP แยกกันชัดเจนใน ADR

Depends on: GW-01

Evidence: `docs/v3/adr/ADR-001-GEMINI-SPARK-OAUTH-GATEWAY.md`; hosting budget ยังต้องยืนยันก่อน external provisioning

### GW-03: Produce data-flow diagram, threat model, and secret ownership matrix

- [x] สร้าง data-flow diagram ครอบคลุม Gemini → Gateway → existing Render MCP
- [x] สร้าง threat model สำหรับ auth edge ใหม่
- [x] สร้าง secret ownership matrix (ใครถือ secret ไหน, scope, rotation owner)

Depends on: GW-02

Evidence: `docs/v3/V3_GEMINI_SPARK_OAUTH_GATEWAY_SECURITY.md`

**Phase 1 Acceptance Gate**: ผู้ใช้อนุมัติ Blocking Decisions ทั้งหมด, ขอบเขต 3 component แยกกันชัดเจน, ไม่มี production secret ใน spike, ยืนยันว่า Gateway เป็น additive auth edge ไม่ใช่ MCP service ตัวที่สอง

## Phase 2 — Provision Gateway-Only Upstream Credential

### GW-04: Provision `GATEWAY_UPSTREAM_BEARER`

- [x] สร้าง `GATEWAY_UPSTREAM_BEARER` ใหม่
- [x] เพิ่ม token ใหม่เข้า `MCP_REMOTE_BEARER_TOKENS` แบบ add-only (เก็บ user bearer tokens เดิมทุกตัวไว้)
- [x] ตรวจ overlap window ที่ token เดิมและ gateway token ใช้งานพร้อมกันได้
- [x] verify gateway token เรียก upstream read-only contracts ได้ครบตาม deployed version

Depends on: GW-03

Evidence: existing MCP env เก็บ bearer เดิมและ gateway-only bearer พร้อมกัน; Gemini sync `28` tools และเรียก V3 read-only tools ผ่าน Gateway สำเร็จ; ไม่มี token literal ในหลักฐาน

### GW-05: Write rotation and emergency revoke runbook

- [x] จัดทำ rotation runbook: add new gateway token → verify upstream access → switch Gateway → observe traffic → remove old gateway-only token
- [x] จัดทำ emergency revoke procedure สำหรับ gateway token โดยไม่แตะ user tokens
- [x] บันทึก runbook ไว้ใน docs (ไม่มี token literal)

Depends on: GW-04

Evidence: `docs/v3/V3_GEMINI_SPARK_GATEWAY_CREDENTIAL_RUNBOOK.md`; rehearsal รอ credential/staging จริง

**Phase 2 Acceptance Gate**: direct bearer เดิมยังผ่าน remote verification, gateway bearer เรียก upstream ได้ครบ, Gateway ไม่รู้จัก `MCP_REMOTE_PROXY_SHARED_SECRET`, ไม่มี token literal ใน Git/docs/logs/PR text

## Phase 3 — Implement Authorization Configuration And Resource Gateway

### GW-06: Implement Authorization Configuration

- [ ] Authorization Code + PKCE `S256` เท่านั้น
- [x] exact-match redirect URI allowlist
- [ ] `state` validation
- [x] consent และ identity policy ตามที่อนุมัติใน ADR
- [x] refresh token เฉพาะเมื่อ staging handshake ยืนยันว่าจำเป็น
- [x] static client registration เป็น default; restricted DCR เฉพาะเมื่อ Gemini Spark ต้องการจริง
- [x] `nonce` เฉพาะ OIDC/provider-mandated flow

Depends on: GW-05

Evidence: Auth0 API/Application ใช้ RS256, audience-bound `mcp:read`, Authorization Code, exact Gemini callback, owner/client allowlists, no refresh-token grant และ static registration; PKCE S256 enforcement กับ state-mismatch negative test ยัง pending

### GW-07: Publish OAuth Resource Contract

- [x] publish `/.well-known/oauth-protected-resource` (RFC 9728)
- [x] ชี้ไปยัง Authorization Server ที่เลือก
- [x] unauthenticated `/mcp` ตอบ `401` พร้อม `WWW-Authenticate: Bearer` ที่มี `resource_metadata`
- [x] validate token claims: issuer, expiration/revocation, resource/audience (RFC 8707), scope `mcp:read`, subject, client identity
- [x] รองรับ Auth0 JWT ผ่าน JWKS

Depends on: GW-06

Evidence: `oauth-gateway/src/{server,token-verifier}.js`; `oauth-gateway/test/{server,token-verifier}.test.js`; local suite 27/27 ผ่าน

### GW-08: Implement Safe Proxy Contract

- [x] ตรึง upstream origin และ `/mcp` path ใน server-side configuration (client เปลี่ยนปลายทางไม่ได้)
- [x] ปฏิเสธเฉพาะ routing controls ที่ Gateway นิยามเอง — ห้าม block/inspect/rewrite JSON-RPC tool arguments (เช่น `repo`, `branch`, `commit`, `target`)
- [x] ตรวจ request-size limit และ JSON-RPC shape แล้วส่ง body เดิมต่อโดยไม่เปลี่ยน semantics
- [x] strip request headers: client `Authorization`, cookies, proxy/internal secrets, hop-by-hop headers
- [x] inject เฉพาะ `Authorization: Bearer <GATEWAY_UPSTREAM_BEARER>` ไป upstream
- [x] strip sensitive/hop-by-hop response headers ก่อนส่งกลับ client
- [x] preserve MCP-required headers/behavior: `Accept`, `Content-Type`, `MCP-Protocol-Version`, `MCP-Session-Id`, `Last-Event-ID`, streaming/backpressure, cancellation, SSE reconnect

Depends on: GW-07

Evidence: `oauth-gateway/src/{config,headers,server}.js`; byte-preservation, routing, header, active-SSE, `Last-Event-ID`, cancellation และ timeout tests ผ่าน; real upstream staging gate ยัง pending

### GW-09: Implement Session Security

- [x] bind `MCP-Session-Id` กับ tuple `(issuer, subject, client_id)`
- [x] ปฏิเสธ session reuse ข้าม identity
- [x] ระบุ scaling constraint ชัดเจนหากใช้ single instance ระยะแรก
- [x] ก่อน scale หลาย instance ต้องมี shared session mapping หรือ proven session affinity

Depends on: GW-08

Evidence: `oauth-gateway/src/security.js`; cross-identity tests; ADR/README ระบุ single-instance constraint

### GW-10: Implement Security Controls

- [x] TLS-only
- [x] per-subject/client/IP rate limits + global rate limit
- [x] request body-size limit
- [x] upstream connection และ response timeouts
- [x] CORS deny-by-default เว้นแต่มี browser requirement ที่ยืนยันแล้ว
- [x] log redaction สำหรับ tokens, codes, cookies, secrets, sensitive body content
- [x] structured audit events โดยไม่บันทึก source code หรือ credentials
- [x] ยืนยัน read-only capability boundary ตรงกับ upstream

Depends on: GW-09

Evidence: `oauth-gateway/src/{server,security}.js`; local security tests ผ่าน; Gemini sync `28` upstream tools และ representative V3 read-only calls สำเร็จ

**Phase 3 Acceptance Gate**: automated tests ใน Phase 5 ผ่านบน staging, Gateway ไม่เพิ่ม/ลบ/เปลี่ยน tool contracts, request/response headers และ sessions ไม่รั่วข้าม identity

## Phase 4 — Staging Deployment And Real Gemini Handshake

### GW-11: Deploy staging Gateway

- [x] deploy Gateway บน staging URL แยกจาก production MCP URL เดิม
- [x] ตั้ง staging OAuth client และ allowlist เฉพาะผู้ทดสอบ

Depends on: GW-10

Evidence: Render service `srv-d9p1pf7qj5pc738io7v0`, Singapore/Free/single-instance; Auth0 static client จำกัด `mcp:read`, owner subject และ client allowlists; deploy `dep-d9p2jobm8hqs73a65lo0` live at commit `f57982caf65a598aa8bef0bfe71a8023ec928e96`

### GW-12: Generic MCP client smoke test on staging

- [ ] discovery
- [ ] authorization
- [ ] `initialize`
- [ ] `tools/list`
- [ ] representative read-only `tools/call`

Depends on: GW-11

Evidence: real Gemini client ผ่าน lifecycle และ tool calls แล้วใน GW-13; standalone generic OAuth MCP client harness ยัง pending เพื่อคง gate นี้แยกจาก Gemini-specific verification

### GW-13: Real Gemini Spark handshake and evidence archive

- [x] เชื่อม Gemini Spark จริงกับ staging
- [x] บันทึกและ archive handshake evidence (metadata fetches, `401` challenge, authorization request, token exchange outcome แบบ redact secrets, first MCP session, session/reconnect behavior)
- [x] แก้ Gemini-specific deviations ก่อนผ่าน phase

Depends on: GW-12

Evidence: `docs/v3/V3_GEMINI_SPARK_OAUTH_GATEWAY_STAGING_EVIDENCE.md`; SSE InitializeResult regression ใน `oauth-gateway/test/server.test.js`

**Phase 4 Acceptance Gate**: Gemini Spark จริงเชื่อม staging สำเร็จ, evidence ไม่มี token/client secret/authorization code, production canary จะไม่ใช่การเชื่อม Gemini ครั้งแรก, staging failures ไม่กระทบ existing Render MCP users

## Phase 5 — Validation And Regression Gates

### GW-14: OAuth negative tests

- [x] missing token
- [x] expired/revoked token
- [x] wrong issuer
- [x] wrong resource/audience
- [x] insufficient scope
- [x] invalid client identity
- [x] redirect URI mismatch
- [ ] `state` mismatch
- [ ] PKCE downgrade หรือ verifier mismatch
- [x] invalid JWKS signature หรือ failed introspection
- [ ] restricted DCR policy violation หากเปิด DCR

Depends on: GW-13

Evidence: `oauth-gateway/test/token-verifier.test.js`; Auth0 staging logs ยืนยัน callback mismatch ถูก reject ก่อนเพิ่ม exact Gateway callback; state/PKCE negative tests ยัง pending

### GW-15: MCP protocol tests

- [x] `initialize`
- [x] `tools/list`
- [x] representative `tools/call`
- [x] JSON-RPC errors
- [x] SSE streaming (local integration)
- [x] cancellation (local integration)
- [x] reconnect ด้วย `Last-Event-ID` (header preservation local integration)
- [ ] session continuity
- [x] cross-identity session reuse ต้อง fail
- [x] upstream timeout/disconnect behavior (local integration)

Depends on: GW-13

Evidence: `oauth-gateway/test/server.test.js`; 28/28 local tests ผ่าน; real Gemini MCP lifecycle และ V3 tool calls ผ่าน staging

### GW-16: Header and secret hygiene tests

- [x] client authorization/cookies ไม่ไปถึง upstream
- [x] upstream bearer ไม่กลับไปหา client
- [x] proxy/internal headers ไม่รั่วสองทิศทาง
- [x] hop-by-hop headers ถูกกรอง
- [x] logs ไม่บันทึก credentials หรือ sensitive body

Depends on: GW-13

Evidence: `oauth-gateway/test/{server,security}.test.js`; 28/28 local tests ผ่าน

### GW-17: Legacy regression gates

- [x] existing direct bearer endpoint ผ่าน `verify:mcp:remote:v3`
- [x] local `stdio` MCP test suite ผ่าน (`cd mcp-server && npm test`)
- [x] tool names, schemas และ contracts ตรงกับ upstream deployed version
- [x] remote read-only boundary ไม่เปลี่ยน
- [x] preview bundle ยัง `available` และ `fresh`
- [x] existing Codex, Claude และ Cursor configs ไม่ต้องแก้

Depends on: GW-14, GW-15, GW-16

Evidence: `2026-08-04`: MCP suite 54/54; remote legacy 8/8; remote V3 19/19; hosted commit/bundle `227b6e2c915bf675bf9d5b04f26b90dd0d838670`, 28 tools, 16 V3 read-only, generation/write tools excluded; Gateway changes are isolated under `oauth-gateway/`

**Phase 5 Acceptance Gate**: ทุก security/protocol/regression gate ผ่านบน staging, ไม่มี unresolved high-severity finding, rollback rehearsal สำเร็จ

## Phase 6 — Production Canary, Rollout And Rollback

### GW-18: Production rollout

- [ ] สร้าง production OAuth client
- [ ] ลงทะเบียน exact redirect URI
- [ ] deploy production Gateway URL ใหม่โดยไม่ทับ endpoint เดิม
- [ ] ใช้ production gateway-only bearer
- [ ] เปิดให้ Gemini Spark account แบบ allowlist จำนวนเล็กน้อย
- [ ] ทดสอบ discovery, authorization, MCP initialize, tool calls และ streaming บน production

Depends on: GW-17

Evidence: _pending_

### GW-19: Monitoring

- [ ] authorization success/failure rate
- [ ] JWKS/introspection failures
- [ ] gateway `401`/`403`
- [ ] upstream `401`/`5xx`
- [ ] latency และ timeouts
- [ ] stream disconnect/reconnect
- [ ] session identity mismatch
- [ ] rate-limit events
- [ ] secret-redaction failures
- [ ] monitor อย่างน้อย 24–72 ชั่วโมงก่อนขยายผู้ใช้

Depends on: GW-18

Evidence: _pending_

### GW-20: Rollback rehearsal

- [ ] ปิดหรือ revoke Gemini OAuth client
- [ ] disable Gateway routing หรือ production gateway URL
- [ ] รอ active MCP sessions drain
- [ ] revoke เฉพาะ gateway-only upstream bearer
- [ ] ยืนยัน existing Render endpoint และ user bearer tokens ยังทำงาน
- [ ] เก็บ incident evidence ที่ redact แล้วสำหรับแก้ไขก่อน rollout รอบใหม่

Depends on: GW-18

Evidence: _pending_

### GW-21: Gemini onboarding docs

- [ ] เพิ่ม Gemini onboarding docs แบบ additive โดยไม่แทนที่คู่มือ client เดิม (`docs/v3/V3_REMOTE_MCP_GUIDE.md` และเอกสารที่เกี่ยวข้อง)

Depends on: GW-18

Evidence: _pending_

Draft staging onboarding ถูกเพิ่มแบบ additive ใน `docs/v3/V3_REMOTE_MCP_GUIDE.md`; checkbox นี้ยังรอ production URL/client และ production verification ตาม dependency

**Phase 6 Acceptance Gate**: Gemini canary ใช้งานจริงได้ตลอด observation window, legacy regression gates ยังผ่าน, monitoring ไม่มี secret leakage หรือ session isolation failure, rollback สามารถปิด Gateway โดยไม่หยุด existing MCP users

## Definition Of Done

- [ ] Blocking decisions ได้รับอนุมัติและบันทึกใน ADR (รอยืนยัน hosting budget)
- [x] Authorization Server และ Resource Gateway แยก responsibility ชัดเจน
- [x] ไม่มี hand-rolled Authorization Server endpoints
- [x] Gemini Spark ผ่าน staging discovery, OAuth และ MCP handshake จริง
- [x] staging handshake evidence ถูก archive โดยไม่มี secret
- [ ] Production Gemini canary ผ่าน OAuth, `initialize`, `tools/list`, representative Widget V3 reads, streaming, cancellation และ reconnect
- [x] RFC 9728 metadata, `WWW-Authenticate` และ RFC 8707 resource binding ผ่าน local validation
- [x] JWT/JWKS ทำงานตาม Auth0-compatible contract ใน local cryptographic tests
- [ ] PKCE S256, `state`, exact redirect allowlist และ registration policy ผ่าน security tests
- [x] MCP session ถูก bind กับ OAuth identity และป้องกัน cross-user reuse
- [x] Header filtering, rate limits, body limits, timeouts และ log redaction ผ่าน local tests
- [x] Gateway ไม่มี config/input สำหรับ `MCP_REMOTE_PROXY_SHARED_SECRET`
- [x] Gateway inject เฉพาะ gateway-only upstream bearer
- [x] Existing direct bearer endpoint และ local `stdio` ผ่าน regression โดยไม่แก้ config
- [x] Upstream tool contracts, read-only boundary และ preview freshness ไม่เปลี่ยนจาก deployed version
- [ ] Gateway credential rotation runbook ผ่าน rehearsal
- [ ] Monitoring, incident response และ rollback runbooks พร้อมใช้
- [ ] Rollback Gateway ได้โดย existing Render MCP ยังคงให้บริการ

## Reference

- Plan: [`docs/v3/V3_GEMINI_SPARK_OAUTH_GATEWAY_PLAN.md`](../docs/v3/V3_GEMINI_SPARK_OAUTH_GATEWAY_PLAN.md)
- ห้ามเริ่ม provision infrastructure, secrets หรือ production deployment จนกว่า Blocking Decisions จะได้รับอนุมัติตามแผน
