---
name: flutter-widget-v3-preview
description: Open an interactive live browser preview of a Widget V3 component from `flutter-widget-wallet-mcp` from ANY repo — including repos with no Flutter/Dart — by downloading a published, commit-addressed Flutter Web bundle and serving it locally. Also refreshes standalone previews inside the source repo. Use when someone wants to see or inspect a V3 widget running.
---

# Flutter Widget V3 Preview

Open an interactive, live browser preview of a Widget V3 component. This works from ANY repo — including repos with no Flutter/Dart SDK, no `pubspec.yaml`, and no Flutter source — because the source repo publishes a compiled, commit-addressed Flutter Web bundle that a small dependency-free Node launcher downloads, verifies, and serves on loopback. Widget V3 is isolated from legacy widgets/theme (never import legacy `theme_color.dart` or call `ThemeColors.get()`), and this repo has no Widgetbook; never generate or reference Widgetbook use cases.

## Two Modes

- **Published consumer mode (default)** — use from any repo. Never installs Flutter/Dart, never writes into the workspace. Resolves a published bundle and serves it locally on `127.0.0.1`.
- **Source-development mode** — only inside the Widget V3 *source* repo when you need a preview of uncommitted working-tree changes and Flutter is installed locally.

Choose published consumer mode by default. Use source-development mode only when the current workspace actually contains the preview host source (`lib/preview_v3/`) AND the user explicitly wants a working-tree (uncommitted) preview.

## Published Consumer Mode (default)

1. Resolve delivery metadata via MCP:
   - Call `get_v3_widget_preview` (or `get_v3_widget_metadata`) for the named widget. Read `previewDelivery` (`bundleUrl`, `sha256`, `sourceCommit`, `entryPath`, `schemaVersion`) and `previewSlug`.
   - If the response instead has `previewDeliveryStatus` with `available: false`, the bundle is not published (`NOT_BUILT`) or stale (`STALE_BUNDLE`): report the exact code/message and stop. Do NOT build it locally.
   - Never invent a `bundleUrl`/slug; if no widget matches, say so and suggest `flutter-widget-v3-search`.
2. Launch the preview with the bundled launcher (Node, zero dependencies), as a background process so it keeps serving:
   ```bash
   node <skill-dir>/assets/launch-v3-preview.mjs \
     --delivery-json '<the previewDelivery JSON object>' \
     --slug <previewSlug> --token "$MCP_REMOTE_BEARER_TOKEN"
   ```
   The launcher downloads to the OS user cache (outside the workspace), verifies the SHA-256, safe-extracts, serves on `127.0.0.1`, and prints one JSON line `{"ok":true,"url":"http://127.0.0.1:<port>/#/<slug>",...}` only after an HTTP readiness probe passes.
3. Hand the requester the exact `url` from that JSON — only after the launcher reports `ok:true`. Never send a URL that has not been confirmed reachable.
4. Warm reuse is automatic: re-running for the same commit prints `reused:true` with the same port. Stop servers with `node <skill-dir>/assets/launch-v3-preview.mjs --stop-all` when done.

### Fallbacks (published consumer mode)
- `UNAUTHORIZED` / missing bearer token: ask the user for the hosted MCP bearer token and pass it via `--token`; never embed it in a URL or log it.
- `NOT_BUILT` / `STALE_BUNDLE`: report it; the fix is to push the source commit so CI publishes the bundle — do NOT install Flutter or build locally.
- `RUNTIME_MISSING`: neither `python3` nor `node` is available to serve; report the requirement.
- `CHECKSUM_MISMATCH` / `UNSAFE_ARCHIVE` / `DOWNLOAD_FAILED`: the launcher fails closed; report the code and never serve a partial/unsafe bundle.

### Consumer mode guardrails
- Never call `flutter`, `dart`, `flutter pub get`, `flutter-widget-v3-install`, or any code-generation tool in consumer mode.
- Never write Flutter files, a preview host, or a bundle into the consumer workspace — the launcher uses the user cache only, leaving `git status` unchanged.
- Never generate or reference Widgetbook use cases, `@UseCase`, or `lib/widgetbook*` files — none exist in this repo.
- Never send a localhost URL before the launcher confirms readiness.

## Source-Development Mode (source repo only)

Use only inside the Widget V3 source repo when you need a preview of uncommitted working-tree changes and Flutter is installed locally.

1. Create or refresh `preview_v3_<widget>.dart` (Light/Dark toggle, mirroring the `V3MiniButton` pilot) if needed.
2. Run `dart run tool/generate_v3_preview_registry.dart` after adding or renaming a preview; never hand-edit `preview_registry.g.dart`.
3. Start the local host as a background process with `./scripts/serve-v3-preview.sh`, poll readiness, and hand back the exact URL it prints.
4. If Flutter is missing or the build fails, report the exact error — do not claim the preview is live.

## MCP Tools

- `get_v3_widget_preview`
- `get_v3_widget_metadata`

## Guardrails

- Default to published consumer mode; only use source-development mode inside the source repo for uncommitted changes.
- Keep Widget V3 isolated from the legacy theme; never import `theme_color.dart` or call `ThemeColors.get()`.
- This repo has no Widgetbook; do not add it back or generate Widgetbook boilerplate.
- Never hand back a preview URL before HTTP readiness is confirmed.
