# Widget V3 Zero-Flutter Consumer Preview Tasks

สร้างเมื่อ: `2026-07-14 15:11:16 +0700`
อัปเดตล่าสุดเมื่อ: `2026-07-14 17:40:00 +0700`

Execution checklist นี้แตกจาก [`docs/V3_ZERO_FLUTTER_PREVIEW_PLAN.md`](../docs/V3_ZERO_FLUTTER_PREVIEW_PLAN.md) และต่อยอดจาก VP-01–VP-10 ที่ปิดแล้ว โดยไม่แก้ evidence ย้อนหลังใน `V3_WEB_PREVIEW_TASKS.md`

Frozen contract: [`docs/v3/V3_ZERO_FLUTTER_PREVIEW_CONTRACT.md`](../docs/v3/V3_ZERO_FLUTTER_PREVIEW_CONTRACT.md) · Rollout/rollback: [`docs/v3/V3_ZERO_FLUTTER_PREVIEW_ROLLOUT.md`](../docs/v3/V3_ZERO_FLUTTER_PREVIEW_ROLLOUT.md)

> Verification note: all code, unit/integration tests, the zero-Flutter acceptance harness, and the real headless-browser matrix pass locally. Items that require a real push to GitHub Actions, GitHub Releases, or a live Render deploy with the hosted bearer secret are explicitly marked **LIVE-PENDING** — they are code/config-complete and locally exercised, but not yet run against live infrastructure from this sandbox.

## Global Guardrails

- [x] consumer repo ไม่ต้องมี Flutter/Dart/project files — acceptance harness runs empty-git/react/plain with Flutter&Dart stripped from `PATH`
- [x] consumer flow ไม่เขียนไฟล์เข้า workspace; ใช้ user cache เท่านั้น — worktree porcelain identical before/after in all 3 scenarios
- [x] bundle immutable ตาม full source commit และ verify SHA-256 — commit-addressed cache dir + launcher verifies sha256, fails closed on mismatch
- [x] bind local server เฉพาะ loopback — launcher binds `127.0.0.1` only
- [x] ไม่ใส่ bearer token ใน URL, log, cache หรือ browser history — `urlContainsSecret` guard + acceptance "token not persisted in cache" checks
- [x] ใช้ Render service เดิมและ additive MCP contract — new HTTP route + `previewDelivery` are additive; 49/49 MCP tests incl. legacy snapshots pass
- [x] คง source-development preview flow เดิม — `scripts/serve-v3-preview.sh` + `lib/preview_v3/` untouched; full `flutter test` 182/182
- [x] ห้ามส่ง local URL ก่อน HTTP readiness ผ่าน — launcher prints URL only after health-probe readiness

## Exit Criteria

- [x] empty/non-Flutter repo เปิด interactive Widget V3 local preview ได้โดย `PATH` ไม่มี Flutter/Dart — acceptance 17/17 (GET / 200 + health commit/sha match)
- [x] consumer worktree ก่อน/หลังไม่เปลี่ยน
- [x] preview source commit ตรงกับ MCP freshness และ bundle manifest — catalog parity + delivery-route parity checks (live endpoint parity is **LIVE-PENDING** via `verify:mcp:remote:v3`)
- [x] cold/warm/concurrent/error-path tests ผ่าน — acceptance harness covers all
- [x] Skills V3 ทั้ง 3 packs ใช้ published consumer mode เป็น default
- [x] source-development mode ยังผ่าน regression
- [ ] remote Render verification ผ่าน — **LIVE-PENDING** (needs deploy + hosted bearer secret); browser E2E ผ่านแล้ว (7/7)

## Phase 1 — Contract And Portability Proof

### ZP-01: Freeze zero-Flutter consumer contract

- [x] เพิ่ม schema fixture สำหรับ manifest และ `previewDelivery`
- [x] ระบุ cache path, port policy, auth boundary และ error codes
- [x] ระบุ semantics ของ published preview เทียบ source-development preview

Depends on: VP-10

Evidence: `mcp-server/v3/bundle_contract.js` (schemaVersion 1, `validateBundleManifest`, `buildPreviewDelivery`, `urlContainsSecret`, `V3_PREVIEW_ERROR_CODES`, cache-path constants); fixture `mcp-server/tests/fixtures/v3_preview_bundle/manifest.json`; human contract `docs/v3/V3_ZERO_FLUTTER_PREVIEW_CONTRACT.md`; tests `mcp-server/tests/v3/bundle_contract.test.js` 6/6.

### ZP-02: Prove compiled bundle portability

- [x] build bundle จาก source repo ปัจจุบัน
- [x] serve จาก temporary non-Flutter directory โดยซ่อน Flutter/Dart จาก `PATH`
- [x] verify route, assets, Light/Dark, interaction และ reload
- [x] verify temp consumer Git worktree unchanged

Depends on: ZP-01

Evidence: `flutter build web --release -t lib/preview_v3/main.dart` → 95-file bundle; served extracted bundle from a temp non-Flutter git repo with `/development/flutter/bin` stripped (flutter&dart both absent) → `/`, `index.html`, `main.dart.js`, `flutter_bootstrap.js`, `assets/AssetManifest.bin` all HTTP 200; consumer worktree porcelain unchanged. Real headless Chrome (`scripts/v3-preview-bundle/browser-verify.mjs`, Playwright) 4/4: interactive render, fragment route preserved, survives reload, no console errors. Full interactive matrix in ZP-12.

## Phase 2 — Source Build And Distribution

### ZP-03: Generate deterministic bundle manifest

- [x] pack `build/web` เป็น deterministic archive
- [x] include schema version, source SHA, created time, entry path และ registered slugs
- [x] generate SHA-256 และ verification tests
- [x] reject dirty/unknown source revision ใน publish mode

Depends on: ZP-02

Evidence: `scripts/v3-preview-bundle/pack-v3-preview-bundle.mjs` (`packBundle()` core + CLI). Pure-Node deterministic ustar (mtime/uid/gid=0, sorted, prefix-split) + `zlib.gzipSync` (no filename/mtime header) → byte-identical across runs, stable sha256. Rejects dirty worktree, non-40hex commit, empty registry. Tests `scripts/v3-preview-bundle/pack-v3-preview-bundle.test.js` 5/5.

### ZP-04: Add source CI bundle pipeline

- [x] run registry/analyze/test/web-build gates
- [x] publish commit-addressed archive + manifest
- [x] update latest pointer หลัง gates ผ่านแบบ atomic
- [x] retain CI evidence และ document rollback/pinning

Depends on: ZP-03

Evidence: `.github/workflows/v3-preview-bundle.yml` — gates (registry `--check`, format, analyze, `flutter test test/preview_v3/ test/tool/`, build web) → pack `--commit ${{ github.sha }}` → sourceCommit parity check → upload artifact → `gh release create v3-preview-<sha>` (immutable) → recreate `v3-preview-latest` pointer. YAML validated (15 steps). Rollback documented in `docs/v3/V3_ZERO_FLUTTER_PREVIEW_ROLLOUT.md`. **LIVE-PENDING**: the actual Actions run + published releases require a real push to `main`.

### ZP-05: Implement stable bundle delivery endpoint

- [x] เลือก GitHub Release asset หรือ versioned storage contract
- [x] support authenticated streaming download
- [x] add cache headers/content length/checksum metadata
- [x] verify private/public repository auth behavior

Depends on: ZP-04

Evidence: `mcp-server/v3/bundle_store.js` (`LocalDirBundleStore` + `GitHubReleaseBundleStore`, injected fetch, BundleStoreError codes). HTTP route in `mcp-server/http-server.js`: `GET /v3/preview-bundle/manifest.json` + `/<commit|latest>.tar.gz`, bearer-authenticated, streamed (never base64), `content-length` + `etag`=sha256 + `cache-control` immutable(commit)/no-store(latest) + `x-bundle-source-commit`. Private-repo auth via server-side `MCP_PREVIEW_BUNDLE_GH_TOKEN`; public repo needs none. Tests `mcp-server/tests/v3/preview_bundle_http.test.js` 3/3 (auth 401, streamed archive headers, bad/unknown commit).

## Phase 3 — MCP Contract

### ZP-06: Add bundle catalog/provider

- [x] isolate delivery lookup from widget source catalog
- [x] validate manifest schema and source SHA parity
- [x] expose freshness/availability health
- [x] cover missing, stale และ malformed bundle

Depends on: ZP-05

Evidence: `mcp-server/v3/bundle_catalog.js` `V3BundleCatalog` — `describeDelivery` (available / STALE_BUNDLE / NOT_BUILT / MALFORMED_MANIFEST), `health()`, `manifest()`, `openArchive()`; secret-free bundleUrl guard; freshness parity vs `resolveFreshnessCommit`. Tests `mcp-server/tests/v3/bundle_catalog.test.js` 7/7 (fresh available, stale, missing-slug, no-bundle, malformed, local stream, GitHub store via fake fetch incl. 404→NOT_BUILT).

### ZP-07: Add `previewDelivery` to V3 preview metadata

- [x] update V3 handlers/contracts additively
- [x] deprecate existing `localPreviewUrl` for remote consumer flow
- [x] add legacy snapshot/regression coverage
- [x] ensure archive is streamed outside MCP JSON

Depends on: ZP-06

Evidence: `mcp-server/v3/handlers.js` `previewDeliveryFields()` adds `previewDelivery` (available) or `previewDeliveryStatus{code,message}` (not built) to `get_v3_widget_metadata`/`get_v3_widget_details`/`get_v3_widget_preview`; `localPreviewUrl` retained (source-dev only, deprecated for remote per contract doc). Optional `v3BundleCatalog` wired through `createToolDispatcher` (default null = backward compatible). Tests `mcp-server/tests/v3/preview_delivery.test.js` 3/3; legacy snapshots stable (`npm test` 49/49). Archive is streamed by the HTTP route, never embedded in MCP JSON.

## Phase 4 — Repo-Independent Launcher

### ZP-08: Implement secure cache/download layer

- [x] use platform user cache outside workspace
- [x] lock concurrent download per commit
- [x] download to temp, verify checksum และ atomic install
- [x] prevent archive path traversal/symlink escape
- [x] never persist credentials

Depends on: ZP-07

Evidence: `scripts/v3-preview-bundle/launch-v3-preview.mjs` (zero-dep, Node builtins + system tar). Cache `<userCache>/flutter-widget-wallet/v3-preview/<commit>/`; `withCommitLock` atomic lockdir + stale reclaim; download via fetch (Authorization header, token never persisted), verify sha256, `assertSafeArchive` (rejects symlink/hardlink + absolute + `..`), atomic renameSync install, `.ready.json`. Bad checksum does NOT destroy a valid warm cache. Verified live + acceptance harness "token not persisted in cache" 3/3.

### ZP-09: Implement local static server lifecycle

- [x] Python 3 baseline + Node.js fallback
- [x] loopback-only bind and free-port selection
- [x] readiness/health response includes commit + checksum
- [x] reuse matching warm server/cache; reject mismatched process
- [x] clean shutdown without deleting immutable cache

Depends on: ZP-08

Evidence: launcher `pickRuntime` python3→node fallback; `freePort` loopback; writes `__preview_health__.json{commit,sha256}` into served dir; `waitReady` health-probe; warm reuse via `servers.json` + `pidAlive` + health match (prints `reused:true`); SIGINT/TERM cleanup removes the entry, keeps cache. Verified: cold serves (GET / 200), warm reuse same port, `--stop-all`, cache survives shutdown.

### ZP-10: Add zero-Flutter acceptance harness

- [x] run from empty Git repo, React repo และ plain directory
- [x] remove Flutter/Dart from effective `PATH`
- [x] assert no consumer file/worktree mutation
- [x] cover cold, warm, concurrent, collision และ corrupt-download cases

Depends on: ZP-09

Evidence: `scripts/v3-preview-bundle/zero-flutter-acceptance.mjs` — **17/17 PASS**. `npm run accept:v3-preview`. Covers 3 repo shapes with Flutter/Dart stripped from PATH; cold (GET / 200 + health match), warm reuse, worktree unchanged, no token leak, concurrent → 1 cache dir, port collision → PORT_UNAVAILABLE, corrupt sha → CHECKSUM_MISMATCH, missing → NOT_BUILT.

## Phase 5 — Skills And Rollout

### ZP-11: Rewrite `flutter-widget-v3-preview` native packs

- [x] Codex pack uses published consumer mode by default
- [x] Claude Code pack matches the same contract
- [x] Kiro pack matches the same contract
- [x] remove install/generate/Flutter checks from consumer mode
- [x] retain explicit source-development mode

Depends on: ZP-10

Evidence: rewrote `flutter-widget-v3-preview/SKILL.md` across all 3 packs (content-parity, per-pack invocation line). Two modes: published consumer mode (default; resolve `previewDelivery` → bundled launcher `assets/launch-v3-preview.mjs` → URL after `ok:true`) + source-development mode (source repo only). Launcher shipped into each pack's `assets/`; `scripts/v3-preview-bundle/launcher-sync.test.js` asserts parity (1/1). `npm run validate:v3-skills` PASS (3×8×18); `check:v3-boundaries` PASS.

### ZP-12: Validate end-to-end browser behavior

- [x] exact widget slug + unknown route
- [x] Light/Dark and interactive states
- [x] narrow viewport, reload and asset loading
- [x] source update produces new cache key/bundle

Depends on: ZP-11

Evidence: `scripts/v3-preview-bundle/browser-verify.mjs --full` **7/7** (real headless Chrome): interactive render, fragment route preserved, survives reload, unknown route no crash, 320×480 no overflow, keyboard Tab no crash, no console errors. Light/Dark toggle is the same `SegmentedButton` verified in VP-06 (identical bundle content). New-cache-key: launcher run with two distinct `--source-commit` values produced two distinct commit cache dirs + separate servers.

### ZP-13: Deploy additively to existing Render service

- [x] deploy bundle metadata/delivery support — code + `render.yaml` env vars additive (`MCP_PREVIEW_BUNDLE_REPO`, `V3_PREVIEW_BUNDLE_BASE_URL`, secret `MCP_PREVIEW_BUNDLE_GH_TOKEN`)
- [x] verify bearer auth and no secret leakage — delivery route reuses `authenticateRequest`; `previewDelivery.bundleUrl` secret-free; token never cached (harness-proven)
- [x] verify source SHA parity against live `/health`/`/info` — checks added to `mcp-server/scripts/verify-remote-v3.js` (`preview-bundle source SHA parity`, `previewDelivery`); `/info` exposes `previewBundle` health
- [ ] run remote MCP V3 verifier and rollback drill — **LIVE-PENDING** (needs deploy + hosted bearer secret; run `npm run verify:mcp:remote:v3` per rollout doc)

Depends on: ZP-12

Evidence: `render.yaml` (10 envVars, valid), `mcp-server/http-server.js` `/info.previewBundle` health, `mcp-server/scripts/verify-remote-v3.js` extended (syntax OK, SKIPs cleanly until a bundle is published), rollout+rollback documented in `docs/v3/V3_ZERO_FLUTTER_PREVIEW_ROLLOUT.md`.

### ZP-14: Switch default and close migration

- [x] published consumer mode becomes default (in the skills) — gated live-evidence switch is documented; **LIVE-PENDING** confirmation after Render deploy
- [x] docs/onboarding explain zero-Flutter contract and freshness — contract + rollout docs; AGENTS.md / MEMORY.md updated
- [x] old `localPreviewUrl` consumer guidance is deprecated — skills + contract doc mark it source-dev-only
- [x] full Flutter/MCP/skill/browser regression passes — see Current Status
- [x] record final evidence and completion timestamp

Depends on: ZP-13

## Current Status (`2026-07-14 17:40:00 +0700`)

Local regression, all green:

- `dart format --output=none --set-exit-if-changed .` → 0 changed (147 files)
- `dart run tool/generate_v3_preview_registry.dart --check` → up to date
- `flutter analyze` → No issues
- `flutter test` (full) → **182/182**
- `npm run check:v3-boundaries` → PASS (71 Dart, 41 changed)
- `npm run validate:v3-skills` → PASS (3 packs × 8 skills × 18 tools)
- `npm run test:v3-preview-bundle` → **6/6** (packer + launcher-sync)
- `cd mcp-server && npm run check:mcp-syntax` → PASS (53 files)
- `cd mcp-server && npm test` → **49/49** (was 30; +19 zero-Flutter tests, legacy snapshots stable)
- `node scripts/v3-preview-bundle/browser-verify.mjs --full` → **7/7** (real headless Chrome)
- `node scripts/v3-preview-bundle/zero-flutter-acceptance.mjs` → **17/17**

Outstanding **LIVE-PENDING** (require infra outside this sandbox):

1. Push to `main` so `.github/workflows/v3-preview-bundle.yml` runs and publishes the first `v3-preview-latest` GitHub Release.
2. Configure `MCP_PREVIEW_BUNDLE_REPO` (+ base URL) on the Render service and deploy.
3. Run `cd mcp-server && MCP_REMOTE_BASE_URL=... MCP_REMOTE_BEARER_TOKEN=... npm run verify:mcp:remote:v3` against the live endpoint and record the result; then flip the skill default confirmation and the rollback drill.

## Recommended Execution Order

```text
ZP-01 → ZP-02 → ZP-03 → ZP-04 → ZP-05 → ZP-06 → ZP-07
      → ZP-08 → ZP-09 → ZP-10 → ZP-11 → ZP-12 → ZP-13 → ZP-14
```
