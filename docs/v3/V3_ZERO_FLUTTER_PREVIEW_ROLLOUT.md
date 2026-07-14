# Widget V3 Zero-Flutter Preview — Rollout & Rollback (ZP-13/ZP-14)

สร้างเมื่อ: `2026-07-14`

Additive rollout of the zero-Flutter preview delivery on the **existing** Render
service `flutter-widget-wallet-mcp` (no second service). All code/config/tests are
merged and green locally; the steps below are the live rollout that requires a
real push + Render dashboard access + the hosted bearer secret.

## What ships

- **CI publish**: `.github/workflows/v3-preview-bundle.yml` builds the preview host,
  packs the immutable commit-addressed bundle, and publishes GitHub Releases
  `v3-preview-<sha>` (immutable) + `v3-preview-latest` (atomic pointer).
- **Delivery endpoint** (additive): `GET /v3/preview-bundle/manifest.json` and
  `/<commit>.tar.gz` on the hosted service, bearer-authenticated, streamed.
- **MCP metadata** (additive): `previewDelivery` on `get_v3_widget_preview` /
  `get_v3_widget_metadata` / `get_v3_widget_details`; legacy fields unchanged.
- **Launcher**: `scripts/v3-preview-bundle/launch-v3-preview.mjs` (also shipped in
  each `flutter-widget-v3-preview` skill pack under `assets/`).

## Rollout steps (live)

1. Merge to `main`. The `v3-preview-bundle` workflow runs the gates and publishes
   the first `v3-preview-latest` release. Confirm the release assets
   (`v3-preview-bundle.tar.gz` + `manifest.json`) exist.
2. In the Render dashboard for `flutter-widget-wallet-mcp`, set env vars:
   - `MCP_PREVIEW_BUNDLE_REPO=<owner>/<repo>` (the repo holding the releases).
   - `V3_PREVIEW_BUNDLE_BASE_URL=https://flutter-widget-wallet-mcp.onrender.com/v3/preview-bundle`.
   - `MCP_PREVIEW_BUNDLE_GH_TOKEN` only if the release repo is private.
   - Ensure `MCP_REMOTE_COMMIT_SHA` matches the deployed commit (freshness parity).
3. Trigger a deploy (auto on the `mcp-server/**` / `lib/**/v3/**` build filter, or
   manual). The delivery route and `previewDelivery` metadata are additive, so
   legacy clients are unaffected.
4. Verify live (needs the bearer secret; not run in the build sandbox):
   ```bash
   cd mcp-server
   MCP_REMOTE_BASE_URL="https://flutter-widget-wallet-mcp.onrender.com/mcp" \
   MCP_REMOTE_BEARER_TOKEN="<token>" \
   npm run verify:mcp:remote:v3
   ```
   Expect: existing V3 checks PASS, generation tools excluded, `preview-bundle
   manifest endpoint` PASS, `preview-bundle source SHA parity` PASS, and
   `get_v3_widget_preview.previewDelivery` PASS (or SKIP with `NOT_BUILT` until the
   first bundle is published — then re-run after CI publishes).
5. Smoke the consumer path from a non-Flutter repo: resolve `previewDelivery` and
   run the launcher; confirm the served URL opens the interactive preview.

## No secret leakage

- The bearer token is used only as an `Authorization` header for MCP calls and the
  delivery download. `previewDelivery.bundleUrl` is secret-free (guarded by
  `urlContainsSecret`). The launcher never writes the token to cache, URL, or logs
  (proven by the ZP-10 acceptance harness "token not persisted in cache" checks).

## Rollback drill

The rollout is additive, so rollback is low-risk:

1. **Fast disable** (no redeploy): unset `MCP_PREVIEW_BUNDLE_REPO` in Render →
   `previewDelivery` reports `NOT_BUILT` and the delivery route serves the local
   dir only; consumers fall back gracefully (skill reports NOT_BUILT).
2. **Full rollback**: roll the Render service back to the previous deploy build.
   Per the existing rollback gotcha, also reset `MCP_REMOTE_COMMIT_SHA` to the old
   commit so `/health`/`/info` freshness stays accurate. The URL and bearer secret
   do not change.
3. Legacy tool contracts, existing V3 tools, and `localPreviewUrl` are untouched by
   a rollback, so no client reconfiguration is needed.

## Status

- **COMPLETE (`2026-07-15`)** — code, config, local tests, GitHub Releases, Render deploy,
  authenticated archive streaming, live verifier, and rollback drill are green.
- Final runtime/bundle commit: `8a44373e6be8535d49b44f8b14bae6f63865f877`.
- GitHub Actions run `29352517196` published immutable + latest assets.
- Render deploy `dep-d9b6s8pkh4rs73cjljag` is live; `/info.previewBundle` reports
  `available:true`, `fresh:true`; corrected `verify:mcp:remote:v3` passes 19/19.
- Rollback drill temporarily selected a disabled bundle source: `/info` returned
  `NOT_BUILT`, all MCP/V3 checks stayed operational (18/18 with delivery SKIPs),
  and restoring the real repo returned the final 19/19 result.
