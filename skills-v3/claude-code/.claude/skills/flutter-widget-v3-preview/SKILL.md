---
name: flutter-widget-v3-preview
description: Open an interactive live browser preview of a Widget V3 component from `flutter-widget-wallet-mcp` from ANY repo — including repos with no Flutter/Dart — by downloading a published, commit-addressed Flutter Web bundle and serving it locally. Also refreshes standalone previews inside the source repo. Use when someone wants to see or inspect a V3 widget running.
---

# Flutter Widget V3 Preview

Invoke with `/flutter-widget-v3-preview` in Claude Code, or ask Claude to preview a Widget V3 component naturally.

Open an interactive, live browser preview of a Widget V3 component. This works from ANY repo — including repos with no Flutter/Dart SDK, no `pubspec.yaml`, and no Flutter source — because the source repo publishes a compiled, commit-addressed Flutter Web bundle that a small dependency-free Node launcher downloads, verifies, and serves on loopback. Widget V3 is isolated from legacy widgets/theme (never import legacy `theme_color.dart` or call `ThemeColors.get()`), and this repo has no Widgetbook; never generate or reference Widgetbook use cases.

## Two Modes

- **Source-development mode (default inside the source repo)** — use whenever the workspace contains both `lib/preview_v3/` and `scripts/serve-v3-preview.sh`. It builds the working tree with the local Flutter SDK and serves it on `127.0.0.1`.
- **Published consumer mode (default outside the source repo)** — use from any other repo, including repos without Flutter/Dart. It never writes into the workspace and serves a verified published bundle locally.

## Mode Selection — Run This First

1. Check the current workspace for both `lib/preview_v3/` and `scripts/serve-v3-preview.sh`.
2. If both exist, select **source-development mode automatically**. Do not call MCP for bundle delivery, do not run the bundled Node launcher, and do not request a bearer token.
3. If either is absent, select **published consumer mode**.
4. Report the selected mode briefly before starting. Never switch from source-development mode to published consumer mode merely because the local build fails; report the local failure instead.

## Published Consumer Mode (outside the source repo)

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
- `UNAUTHORIZED` / missing bearer token: tell the user to set `MCP_REMOTE_BEARER_TOKEN` privately in the shell that launches the agent, then restart the agent. Never ask the user to paste, type, or reveal a token in chat. Never accept a token from conversation text.
- `NOT_BUILT` / `STALE_BUNDLE`: report it; the fix is to push the source commit so CI publishes the bundle — do NOT install Flutter or build locally.
- `RUNTIME_MISSING`: neither `python3` nor `node` is available to serve; report the requirement.
- `CHECKSUM_MISMATCH` / `UNSAFE_ARCHIVE` / `DOWNLOAD_FAILED`: the launcher fails closed; report the code and never serve a partial/unsafe bundle.

### Consumer mode guardrails
- Never call `flutter`, `dart`, `flutter pub get`, `flutter-widget-v3-install`, or any code-generation tool in consumer mode.
- Never write Flutter files, a preview host, or a bundle into the consumer workspace — the launcher uses the user cache only, leaving `git status` unchanged.
- Never generate or reference Widgetbook use cases, `@UseCase`, or `lib/widgetbook*` files — none exist in this repo.
- Never send a localhost URL before the launcher confirms readiness.

## Source-Development Mode (source repo only)

Use automatically whenever the workspace contains `lib/preview_v3/` and `scripts/serve-v3-preview.sh`.

1. Locate or create `lib/widgets/v3/<category>/preview_v3_<widget>.dart` with Light/Dark coverage. Use the existing widget-local preview as source of truth; do not fetch a published bundle.
2. Run `dart run tool/generate_v3_preview_registry.dart`. The generator scans `lib/widgets/v3/**/preview_v3_*.dart` and regenerates `lib/preview_v3/preview_registry.g.dart`. Never hand-edit that generated file.
3. Keep the preview architecture intact: `main.dart` is the thin entrypoint, `preview_app.dart` owns testable routing, `preview_registry.dart` validates/wraps the generated entries, and `preview_registry.g.dart` is generated output.
4. Start `./scripts/serve-v3-preview.sh` as a background process. It regenerates/checks the registry, builds when needed, serves on loopback, and prints the route only after readiness.
5. Poll HTTP readiness and return exactly `http://127.0.0.1:8090/#/<category>/<WidgetClass>` (or the actual host/port printed by the script). Never return an unverified URL.
6. If Flutter is missing or the build fails, report the exact error. Do not fall back to consumer mode and do not claim the preview is live.

## MCP Tools

- `get_v3_widget_preview`
- `get_v3_widget_metadata`

## Guardrails

- Source repo detection always takes precedence: when both local preview-host markers exist, use source-development mode without MCP delivery or a bearer token.
- Never request, accept, repeat, log, or expose bearer tokens in chat; direct users to set `MCP_REMOTE_BEARER_TOKEN` privately in their shell.
- Keep Widget V3 isolated from the legacy theme; never import `theme_color.dart` or call `ThemeColors.get()`.
- This repo has no Widgetbook; do not add it back or generate Widgetbook boilerplate.
- Never hand back a preview URL before HTTP readiness is confirmed.
