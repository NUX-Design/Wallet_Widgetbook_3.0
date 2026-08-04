# Gemini Spark OAuth Gateway Operations Runbook

ใช้กับ production canary ของ OAuth Gateway เท่านั้น Existing MCP endpoint และ direct bearer clients อยู่นอก blast radius ของการปิด Gateway

## Preconditions

- production Auth0 client ใช้ Google OAuth credentials ของโครงการเอง ไม่ใช้ Auth0 development keys
- Gateway และ existing MCP มี gateway-only bearer ที่แยกจาก user bearer tokens
- Render Gateway ใช้หนึ่ง instance จนกว่าจะมี shared session mapping หรือ verified session affinity
- production callback, subject และ client allowlists ผ่าน exact-match review
- generic verifier และ Gemini canary ผ่าน `initialize`, `tools/list` และ representative read-only call

## Monitoring Window

เริ่ม observation window หลัง canary ผ่านครั้งแรก และเฝ้าดูอย่างน้อย `24–72` ชั่วโมงก่อนขยายผู้ใช้ บันทึกเวลาเริ่ม/สิ้นสุด, deploy ID, full commit SHA และจำนวน canary users ใน evidence โดยไม่บันทึก identity จริง

### Render structured log events

| Signal | Event/filter | Canary threshold | Action |
| --- | --- | --- | --- |
| Authorization failures | `gateway.auth_rejected` แยกตาม `reason` | สืบสวนทันทีหาก valid canary flow ล้มเหลวต่อเนื่อง 3 ครั้ง | ตรวจ issuer/audience/scope/allowlists/JWKS |
| Gateway 401/403 | `gateway.auth_rejected`, `gateway.session_rejected` | ไม่มี unexpected 401/403 หลัง canary login สำเร็จ | หยุด rollout; ห้ามขยาย allowlist |
| Upstream 401/5xx | `gateway.request_completed` ที่ `status >= 400` หรือ `gateway.upstream_failed` | 0 upstream 401; 5xx ต้องไม่เกิดต่อเนื่อง | ตรวจ gateway bearer และ upstream health |
| Latency | `gateway.request_completed.latency_ms` | p95 header latency < 5s หลัง warm; แยก cold start | ตรวจ Render metrics/cold start/upstream latency |
| Stream duration/disconnect | `gateway.response_completed.duration_ms`, `gateway.upstream_failed` | ไม่มี repeated abort/timeout สำหรับ canary task | ตรวจ header/idle timeout และ client reconnect |
| Session mismatch | `gateway.session_rejected` reason `session_identity_mismatch` | 0 | ปิด canary client และเริ่ม incident review |
| Rate limiting | `gateway.rate_limited` | 0 สำหรับ traffic canary ปกติ | ตรวจ loop/retry storm ก่อนปรับ limit |
| Initialize validation | `gateway.initialize_rejected` | 0 | หยุด rolloutและตรวจ upstream response contract |
| Secret leakage | log review หา credential-shaped fields | 0 | ปิด client, revoke gateway-only bearer, preserve redacted evidence |

Render Metrics ใช้ตรวจ CPU, memory, instance restarts และ request latency ควบคู่กับ structured logs ห้ามใช้เพียง health endpoint เพื่อสรุปว่า OAuth/MCP lifecycle ปกติ

## Observation Evidence Template

```text
Window: <start ISO-8601> — <end ISO-8601>
Gateway deploy: <deploy id>
Commit: <full SHA>
Canary size: <count only>
Auth success/failure: <counts by redacted reason>
Gateway 401/403: <counts>
Upstream 401/5xx: <counts>
Latency p50/p95/max: <milliseconds>
Stream disconnect/reconnect: <counts>
Session mismatch: <count>
Rate limit: <count>
Secret leakage review: PASS/FAIL
Decision: HOLD / ROLLBACK / EXPAND
```

## Incident Response

1. หยุดขยาย allowlist และเก็บ deploy/commit/timestamp
2. ปิด production Auth0 client เพื่อหยุด authorization/token issuance ใหม่
3. หากสงสัย token compromise ให้ทำตาม `V3_GEMINI_SPARK_GATEWAY_CREDENTIAL_RUNBOOK.md` และ revoke เฉพาะ gateway-only bearer
4. ห้าม rotate หรือลบ existing user bearer tokens
5. ตรวจ existing MCP `/health`, `/info`, legacy verifier และ V3 verifier
6. เก็บเฉพาะ event type, status, latency, hashed identity และ redacted reason
7. แก้ไขบน staging และผ่าน security/regression gates ก่อนเริ่ม canary ใหม่

## Rollback Rehearsal

ทำ rehearsal ด้วย production canary หลัง production deployment พร้อมแล้ว:

1. ปิด production Auth0 client หรือถอด canary user/client access
2. ปิด Gateway route/service สำหรับ traffic ใหม่ โดยไม่แตะ existing MCP service
3. รอ active streams สิ้นสุดตาม stream idle timeout
4. ถอด gateway-only bearer ออกจาก existing MCP bearer list
5. ยืนยัน existing user bearer และ local stdio ยังใช้งานได้
6. ยืนยัน original URL `https://flutter-widget-wallet-mcp.onrender.com/mcp` ไม่เปลี่ยน
7. เก็บผล rehearsal แบบ redact แล้วคืนค่า canary เฉพาะเมื่อทุก regression gate ผ่าน

Rollback ถือว่าสำเร็จเมื่อ Gateway ใช้งานไม่ได้ตามตั้งใจ แต่ existing MCP direct bearer และ local stdio ยังผ่าน verification โดยไม่มี config change
